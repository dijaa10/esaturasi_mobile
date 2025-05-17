// Step 1: First, add the necessary dependencies to your pubspec.yaml
// This is a partial example, add these to your existing dependencies

// In pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.1.1
  dio: ^5.3.2
  http: ^1.1.0
  url_launcher: ^6.1.14
  flutter_pdfview: ^1.3.2
  share_plus: ^7.1.0 # Add this for sharing files
  path: ^1.8.3 # Add this for path manipulation
*/

// Step 2: Add FileProvider configuration to your Android manifest
// In android/app/src/main/AndroidManifest.xml inside the <application> tag:
/*
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
*/

// Step 3: Create the file_paths.xml resource file
// In android/app/src/main/res/xml/file_paths.xml:
/*
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <files-path name="files" path="."/>
    <cache-path name="cache" path="."/>
    <external-cache-path name="external_cache" path="."/>
    <external-files-path name="external_files" path="."/>
</paths>
*/

// Step 4: Update your DetailMateriPage class with the fixed code below

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../model/slug.dart';
import '../model/subjectmatter.dart';
import 'package:share_plus/share_plus.dart';

class DetailMateriPage extends StatefulWidget {
  final Slug slug;

  const DetailMateriPage({Key? key, required this.slug}) : super(key: key);

  @override
  _DetailMateriPageState createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  List<Subjectmatter> materials = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  // Change baseUrl to use IP address that works better with emulators
  final String baseUrl = "http://10.0.2.2:8000";
  // Track selected material name for the app bar title
  String _selectedMaterialName = "";
  // Flag to remember if PDF viewer had errors
  bool _hasPDFOpenError = false;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final int slugId = widget.slug.id;
      print("Fetching materials for slug ID: $slugId");

      final uri = Uri.parse("${baseUrl}/api/materials/slug/$slugId");
      print("Request URL: $uri");

      // Add proper headers to request
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Connection timeout, server might be down");
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Raw response length: ${response.body.length}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception("Server returned empty response");
        }

        // Print the first few characters to debug
        print(
            "First 50 chars of response: ${response.body.length > 50 ? response.body.substring(0, 50) + '...' : response.body}");

        // Trim any whitespace or BOM characters that might be present
        final String cleanedResponse = response.body.trim();

        dynamic decoded;
        try {
          decoded = jsonDecode(cleanedResponse);
        } catch (e) {
          print("JSON decode error: $e");
          print("Response body: $cleanedResponse");
          throw Exception("Failed to decode JSON response: $e");
        }

        if (decoded is! List) {
          print("Invalid data structure, got: ${decoded.runtimeType}");
          throw Exception(
              "Expected a list of materials but got different data structure: ${decoded.runtimeType}");
        }

        final List<dynamic> data = decoded;
        print("Parsed materials data length: ${data.length}");

        setState(() {
          // Properly construct Subjectmatter objects from the JSON data
          materials = data.map((item) => Subjectmatter.fromJson(item)).toList();
          _isLoading = false;

          // Set app bar title to slug name if available
          _selectedMaterialName = widget.slug.title ?? "Material Files";
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Server Error: ${response.statusCode} - ${response.reasonPhrase ?? ''}";
        });
        print(_errorMessage);
      }
    } on SocketException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Network error: Check your connection and make sure the server is running.\nDetails: ${e.message}";
      });
      print("Socket exception: $e");
    } on TimeoutException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Connection timeout: Server might be down or not responding";
      });
      print("Timeout exception: $e");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error fetching materials: ${e.toString()}";
      });
      print("General exception: $e");
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName);

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_library;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = _getFileExtension(fileName);

    switch (extension) {
      case 'pdf':
        return Colors.red.shade400;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green.shade400;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.blue.shade400;
      case 'mp3':
      case 'wav':
        return Colors.purple.shade400;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade700;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _openFile(Subjectmatter materi) async {
    if (materi.filePath.isEmpty) {
      _showErrorDialog('File path is missing',
          'Cannot open file because the file path is empty.');
      return;
    }

    // Update the app bar title to the clicked material name
    setState(() {
      _selectedMaterialName = materi.title;
    });

    // Extract file extension from file_path instead of title
    final String fileExtension = _getFileExtension(materi.filePath);

    // Construct the correct file URL
    final String normalizedPath = materi.filePath.startsWith('storage/')
        ? materi.filePath
        : materi.filePath;

    final String fileUrl = Uri.encodeFull("$baseUrl/storage/$normalizedPath");

    print("Opening file URL: $fileUrl");

    setState(() {
      _isLoading = true;
    });

    try {
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
          setState(() {
            _isLoading = false;
          });
          _openImage(fileUrl, materi.title);
          break;

        case 'pdf':
          try {
            final localFile =
                await _downloadFile(fileUrl, '${materi.title}.pdf');
            setState(() {
              _isLoading = false;
            });

            // Check if the downloaded file exists and has content
            if (await localFile.exists() && await localFile.length() > 0) {
              // Validate PDF file format
              if (await _validatePDFFile(localFile)) {
                _openPdf(localFile.path, materi.title);
              } else {
                throw Exception("Downloaded file is not a valid PDF");
              }
            } else {
              throw Exception("PDF file is empty or corrupt");
            }
          } catch (e) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Error Downloading PDF',
                'Failed to download the PDF file. Please check your internet connection and try again.\n\nDetails: ${e.toString()}');
          }
          break;

        case 'doc':
        case 'docx':
        case 'ppt':
        case 'pptx':
        case 'xls':
        case 'xlsx':
        case 'mp4':
        case 'mp3':
          try {
            // For Office documents, also download locally first
            final localFile = await _downloadFile(
                fileUrl, '${materi.title}.${fileExtension}');
            setState(() {
              _isLoading = false;
            });

            if (await localFile.exists() && await localFile.length() > 0) {
              await _openWithCompatibleApp(localFile);
            } else {
              throw Exception("Document file is empty or corrupt");
            }
          } catch (e) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Error Downloading Document',
                'Failed to download the document. Please check your internet connection and try again.\n\nDetails: ${e.toString()}');
          }
          break;

        default:
          try {
            // For other file types, download locally
            final localFile = await _downloadFile(
                fileUrl, '${materi.title}.${fileExtension}');
            setState(() {
              _isLoading = false;
            });

            if (await localFile.exists()) {
              await _openWithCompatibleApp(localFile);
            } else {
              throw Exception("File could not be downloaded");
            }
          } catch (e) {
            setState(() {
              _isLoading = false;
            });
            _showErrorDialog('Error Opening File',
                'Failed to open the file. Please check your internet connection and try again.\n\nDetails: ${e.toString()}');
          }
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
          'Error Opening File', 'Could not open the file: ${e.toString()}');
    }
  }

  // Validate the PDF file header to ensure it's a valid PDF
  Future<bool> _validatePDFFile(File file) async {
    try {
      // Read the first few bytes of the file to check its header
      final RandomAccessFile raf = await file.open(mode: FileMode.read);
      final List<int> header = await raf.read(5); // Read first 5 bytes
      await raf.close();

      // Check if header matches the PDF signature (%PDF-)
      return String.fromCharCodes(header) == '%PDF-';
    } catch (e) {
      print("Error validating PDF file: $e");
      return false;
    }
  }

  Future<File> _downloadFile(String url, String fileName) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Check if file already exists and has content
      if (await file.exists() && await file.length() > 0) {
        print("File already exists locally, using cached version");
        return file;
      }

      // Show a download progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Downloading $fileName...'),
                ],
              ),
            ),
          );
        },
      );

      // Clear previous interceptors to avoid duplication
      _dio.interceptors.clear();

      // Add logging interceptor for debugging
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: true,
        responseBody: false,
      ));

      // Configure timeout settings
      _dio.options.connectTimeout = 30000; // 30 seconds in milliseconds
      _dio.options.receiveTimeout = 30000; // 30 seconds in milliseconds
      _dio.options.sendTimeout = 30000; // 30 seconds in milliseconds

      // Setup retry variables
      int retryCount = 0;
      const int maxRetries = 3;
      bool downloadSuccess = false;
      Exception? lastException;

      // Implement exponential backoff for retries
      while (!downloadSuccess && retryCount < maxRetries) {
        try {
          // Perform download with proper headers
          final response = await _dio.download(
            url,
            filePath,
            options: Options(
              headers: {
                "Accept": "*/*",
                "User-Agent": "Flutter/1.0",
                "Connection": "keep-alive",
              },
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
              receiveTimeout: 60000, // 60 seconds in milliseconds
            ),
            onReceiveProgress: (received, total) {
              if (total != -1) {
                print(
                    "Download progress: ${(received / total * 100).toStringAsFixed(0)}%");
              }
            },
            deleteOnError: false,
          );

          // Check response status code
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            downloadSuccess = true;
          } else {
            throw Exception(
                "Server returned status code: ${response.statusCode}");
          }
        } catch (e) {
          retryCount++;
          lastException = e as Exception;
          print("Download failed (attempt $retryCount): $e");

          if (retryCount >= maxRetries) {
            throw e; // Re-throw if max retries reached
          }

          // Exponential backoff delay
          final delay = Duration(seconds: retryCount * 2);
          print("Waiting ${delay.inSeconds} seconds before retry");
          await Future.delayed(delay);
        }
      }

      // Make sure the dialog is closed
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close dialog
      }

      // Verify file was downloaded successfully
      if (!downloadSuccess) {
        throw lastException ??
            Exception("Download failed after $maxRetries attempts");
      }

      // Verify file exists and has content
      if (await file.exists() && await file.length() > 0) {
        return file;
      } else {
        throw Exception("Downloaded file is empty or does not exist");
      }
    } catch (e) {
      // Make sure the dialog is closed
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close dialog in case of error
      }

      print("Final download error: $e");
      throw Exception("Error downloading file: $e");
    }
  }

  // Use Share.shareFiles for safely sharing files with other apps
  Future<void> _openWithCompatibleApp(File file) async {
    try {
      await Share.shareFiles(
        [file.path],
        sharePositionOrigin: Rect.fromLTWH(0, 0, 10, 10),
      );
      print("File shared successfully.");
    } catch (e) {
      print("Error sharing file: $e");
      _showErrorDialog(
          "File Sharing Error", "Could not open the file with other apps: $e");
    }
  }

  void _openPdf(String filePath, String fileName) {
    try {
      // Verify the file exists and has content before attempting to open it
      final File pdfFile = File(filePath);
      if (!pdfFile.existsSync()) {
        _showErrorDialog("File Not Found",
            "The PDF file doesn't exist at the specified location");
        return;
      }

      if (pdfFile.lengthSync() <= 0) {
        _showErrorDialog(
            "Empty File", "The PDF file appears to be empty or corrupted");
        return;
      }

      // Check if previous attempts to use PDFView failed
      if (_hasPDFOpenError) {
        _openWithCompatibleApp(pdfFile);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(fileName),
              backgroundColor: const Color(0xFF1976D2),
              elevation: 0,
              actions: [
                // Add option to open with external app
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share file',
                  onPressed: () {
                    Navigator.pop(context);
                    _openWithCompatibleApp(pdfFile);
                  },
                ),
              ],
            ),
            body: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onError: (error) {
                print("Error loading PDF: $error");
                Navigator.pop(context); // Go back if PDF fails to load

                // Flag to remember that PDFView had an error to use external app directly next time
                setState(() {
                  _hasPDFOpenError = true;
                });

                _showErrorDialog(
                    "PDF Error", "Could not load the PDF file: $error");

                // Try to open with external app
                _openWithCompatibleApp(pdfFile);
              },
              onPageError: (page, error) {
                print("Error on page $page: $error");
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print("Exception when opening PDF: $e");
      _showErrorDialog("Error Opening PDF", "An unexpected error occurred: $e");

      // Try fallback to external app
      _openWithCompatibleApp(File(filePath));
    }
  }

  void _openImage(String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(fileName),
            backgroundColor: const Color(0xFF1976D2),
            elevation: 0,
            actions: [
              // Add option to open with external app
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download image',
                onPressed: () async {
                  Navigator.pop(context);
                  // Download image and then open with compatible app
                  try {
                    final localFile = await _downloadFile(url, fileName);
                    _openWithCompatibleApp(localFile);
                  } catch (e) {
                    _showErrorDialog(
                        "Download Error", "Failed to download image: $e");
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF1976D2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading image: $error");

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading image',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Detail: $error',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Try downloading the image directly
                          try {
                            final localFile =
                                await _downloadFile(url, fileName);
                            _openWithCompatibleApp(localFile);
                          } catch (e) {
                            _showErrorDialog("Download Error",
                                "Failed to download image: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                        ),
                        child: const Text('Download Image'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1976D2))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // Use the dynamic title
        title: Text(
          _selectedMaterialName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildSimpleList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMaterials,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleList() {
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada file materi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final materi = materials[index];
        return _buildSimpleFileCard(materi);
      },
    );
  }

  Widget _buildSimpleFileCard(Subjectmatter materi) {
    // Get file extension from filePath instead of title for correct icon display
    final String fileExtension = _getFileExtension(materi.filePath);
    final IconData fileIcon = _getFileIcon(fileExtension);
    final Color fileColor = _getFileColor(fileExtension);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _openFile(materi),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fileColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            fileIcon,
            color: fileColor,
            size: 24,
          ),
        ),
        title: Text(
          materi.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: materi.description != null && materi.description!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  materi.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// Custom exception for timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
