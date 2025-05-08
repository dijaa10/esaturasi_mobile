import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import '../model/slug.dart';
import '../model/materi.dart';

class DetailMateriPage extends StatefulWidget {
  final Slug slug;

  const DetailMateriPage({Key? key, required this.slug}) : super(key: key);

  @override
  _DetailMateriPageState createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  List<Materi> materials = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  // Change baseUrl to use IP address that works better with emulators
  final String baseUrl = "http://10.0.2.2:8000/";
  // Track selected material name for the app bar title
  String _selectedMaterialName = "";

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

      final uri = Uri.parse("${baseUrl}api/materials/slug/$slugId");
      print("Request URL: $uri");

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Connection timeout, server might be down");
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Raw response for materials: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception("Server returned empty response");
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (e) {
          throw Exception("Failed to decode JSON response: $e");
        }

        if (decoded is! List) {
          throw Exception(
              "Expected a list of materials but got different data structure");
        }

        final List<dynamic> data = decoded;

        print("Parsed materials data length: ${data.length}");

        setState(() {
          materials = data.map((item) => Materi.fromJson(item)).toList();
          _isLoading = false;

          // Set app bar title to slug name if available
          _selectedMaterialName = widget.slug.judul ?? "Material Files";
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

  Future<void> _openFile(Materi materi) async {
    if (materi.filePath.isEmpty) {
      _showErrorDialog('File path is missing',
          'Cannot open file because the file path is empty.');
      return;
    }

    // Update the app bar title to the clicked material name
    setState(() {
      _selectedMaterialName = materi.namaFile;
    });

    final String fileUrl = "${baseUrl}storage/${materi.filePath}";
    print("Opening file URL: $fileUrl");
    final String fileExtension = _getFileExtension(materi.namaFile);

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
          _openImage(fileUrl, materi.namaFile);
          break;

        case 'pdf':
          try {
            final localFile = await _downloadFile(fileUrl, materi.namaFile);
            setState(() {
              _isLoading = false;
            });

            // Check if the downloaded file exists and has content
            if (await localFile.exists() && await localFile.length() > 0) {
              _openPdf(localFile.path, materi.namaFile);
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
          try {
            // For Office documents, also download locally first
            final localFile = await _downloadFile(fileUrl, materi.namaFile);
            setState(() {
              _isLoading = false;
            });

            if (await localFile.exists() && await localFile.length() > 0) {
              _openFileWithExternalApp('file://${localFile.path}');
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
            final localFile = await _downloadFile(fileUrl, materi.namaFile);
            setState(() {
              _isLoading = false;
            });

            if (await localFile.exists()) {
              _openFileWithExternalApp('file://${localFile.path}');
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

  Future<File> _downloadFile(String url, String fileName) async {
    try {
      // Get the application documents directory instead of temporary directory
      // This helps with file persistence issues
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Check if file already exists
      if (await file.exists()) {
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

      // Improved Dio configuration with exponential backoff retry
      _dio.options.connectTimeout = 60000; // 60 seconds
      _dio.options.receiveTimeout = 60000; // 60 seconds
      _dio.options.sendTimeout = 60000; // 60 seconds

      // Add request/response interceptors for better debugging
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: true,
        responseBody: false,
      ));

      int retryCount = 0;
      const int maxRetries = 5;
      bool downloadSuccess = false;
      Exception? lastException;

      // Implement exponential backoff for retries
      while (!downloadSuccess && retryCount < maxRetries) {
        try {
          // Use proper headers to avoid server rejections
          final response = await _dio.download(
            url,
            filePath,
            options: Options(
              headers: {"Accept": "*/*", "User-Agent": "Flutter/1.0"},
              followRedirects: true,
              validateStatus: (status) => status! < 500,
            ),
            onReceiveProgress: (received, total) {
              if (total != -1) {
                print(
                    "Download progress: ${(received / total * 100).toStringAsFixed(0)}%");
              }
            },
            deleteOnError: true,
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(fileName),
              backgroundColor: const Color(0xFF1976D2),
              elevation: 0,
              // Share button removed as requested
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
                _showErrorDialog(
                    "PDF Error", "Could not load the PDF file: $error");
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
    }
  }

  Future<void> _openFileWithExternalApp(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // First try with the newer API
      if (await canLaunchUrl(uri)) {
        final bool launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!launched) {
          throw Exception('Failed to launch URL');
        }
      }
      // Fallback to the older API
      else if (await canLaunch(url)) {
        final bool launched = await launch(url);

        if (!launched) {
          throw Exception('Failed to launch URL');
        }
      } else {
        throw Exception('No app found to open this file type');
      }
    } catch (e) {
      print('Error launching URL: $e');
      throw Exception('Could not open the file with any available app: $e');
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

  void _showUnsupportedFileTypeDialog(String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
            const SizedBox(width: 10),
            const Text('Tipe File Tidak Didukung'),
          ],
        ),
        content: Text(
          'Maaf, format file .$fileType tidak dapat dibuka di aplikasi ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1976D2))),
          ),
        ],
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
          // Add a retry button for download errors
          if (title.contains("Error Downloading"))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Retry with external app as fallback
                final fileUrl = message.contains("http://")
                    ? message
                        .substring(message.indexOf("http://"),
                            message.indexOf("http://") + 100)
                        .split(" ")[0]
                    : null;

                if (fileUrl != null) {
                  launchUrl(Uri.parse(fileUrl),
                      mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Open in Browser',
                  style: TextStyle(color: Color(0xFF1976D2))),
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
        // Use the dynamic title instead of the static "Material Files"
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

  Widget _buildSimpleFileCard(Materi materi) {
    final IconData fileIcon = _getFileIcon(materi.namaFile);
    final Color fileColor = _getFileColor(materi.namaFile);

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
          materi.namaFile,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: materi.deskripsi != null && materi.deskripsi!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  materi.deskripsi!,
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
