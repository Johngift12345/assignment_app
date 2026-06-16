import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LibraryPage extends StatefulWidget {
  final String? initialQuery;

  const LibraryPage({super.key, this.initialQuery});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  String _selectedFilter = 'Recent';

  final List<String> _filters = ['Recent', 'All Time', 'Free Only'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchBooks(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
      _books = [];
    });

    try {
      final encoded = Uri.encodeComponent(query);

      // Build URL based on filter
      String urlString;
      if (_selectedFilter == 'Free Only') {
        urlString =
            'https://www.googleapis.com/books/v1/volumes?q=$encoded&filter=free-ebooks&maxResults=30&orderBy=relevance&printType=books';
      } else if (_selectedFilter == 'Recent') {
        urlString =
            'https://www.googleapis.com/books/v1/volumes?q=$encoded&maxResults=40&orderBy=newest&printType=books';
      } else {
        urlString =
            'https://www.googleapis.com/books/v1/volumes?q=$encoded&maxResults=30&orderBy=relevance&printType=books';
      }

      final response = await http
          .get(Uri.parse(urlString))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> books = (data['items'] ?? []);

        // For recent filter keep only 2010+
        if (_selectedFilter == 'Recent') {
          books = books.where((b) {
            final date = b['volumeInfo']?['publishedDate'] ?? '';
            if (date.length >= 4) {
              final year = int.tryParse(date.substring(0, 4));
              return year != null && year >= 2010;
            }
            return false;
          }).toList();
        }

        if (mounted) {
          setState(() {
            _books = books;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to fetch books. Try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No internet connection. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showBookDetails(Map<String, dynamic> book) {
    final info = book['volumeInfo'] ?? {};
    final title = info['title'] ?? 'Unknown Title';
    final authors = (info['authors'] as List?)?.join(', ') ?? 'Unknown Author';
    final publishedDate = info['publishedDate'] ?? 'Unknown';
    final description = info['description'] ?? 'No description available.';
    final thumbnail = info['imageLinks']?['thumbnail']?.toString().replaceAll(
      'http://',
      'https://',
    );
    final previewLink = info['previewLink']?.toString().replaceAll(
      'http://',
      'https://',
    );
    final infoLink = info['infoLink']?.toString().replaceAll(
      'http://',
      'https://',
    );
    final accessInfo = book['accessInfo'] ?? {};
    final viewability = accessInfo['viewability'] ?? 'NO_PAGES';
    final isPublicDomain = accessInfo['publicDomain'] ?? false;
    final epubAvailable = accessInfo['epub']?['isAvailable'] ?? false;
    final pdfAvailable = accessInfo['pdf']?['isAvailable'] ?? false;
    final epubLink = accessInfo['epub']?['downloadLink']?.toString().replaceAll(
      'http://',
      'https://',
    );
    final pdfLink = accessInfo['pdf']?['downloadLink']?.toString().replaceAll(
      'http://',
      'https://',
    );

    final canPreview = viewability == 'PARTIAL' || viewability == 'ALL_PAGES';
    final canDownload = isPublicDomain || epubAvailable || pdfAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: thumbnail != null
                                ? Image.network(
                                    thumbnail,
                                    width: 90,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _noCoverWidget(90, 120),
                                  )
                                : _noCoverWidget(90, 120),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.blueGrey[900],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 13,
                                      color: Colors.blueGrey[400],
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        authors,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey[500],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: Colors.blueGrey[400],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      publishedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // Access badges
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (canPreview)
                                      _badge('Preview', Colors.blue),
                                    if (canDownload)
                                      _badge('Downloadable', Colors.green),
                                    if (isPublicDomain)
                                      _badge('Public Domain', Colors.teal),
                                    if (!canPreview && !canDownload)
                                      _badge('Info Only', Colors.orange),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Divider(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                      ),
                      SizedBox(height: 12),

                      // Description
                      Text(
                        'About this book',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.blueGrey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        description.length > 300
                            ? '${description.substring(0, 300)}...'
                            : description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.blueGrey[600],
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Action buttons
                      if (canPreview && previewLink != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _launchUrl(previewLink),
                              icon: Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Read Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),

                      if (epubLink != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _launchUrl(epubLink),
                              icon: Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Download EPUB',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[600],
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),

                      if (pdfLink != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _launchUrl(pdfLink),
                              icon: Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Download PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),

                      if (infoLink != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _launchUrl(infoLink),
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.blueGrey[700],
                              ),
                              label: Text(
                                'View on Google Books',
                                style: TextStyle(
                                  color: Colors.blueGrey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.blueGrey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Find free PDF on Google
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final q = Uri.encodeComponent(
                              '$title $authors free PDF',
                            );
                            _launchUrl('https://www.google.com/search?q=$q');
                          },
                          icon: Icon(
                            Icons.search_rounded,
                            color: Colors.blueGrey[500],
                          ),
                          label: Text(
                            'Find Free PDF on Google',
                            style: TextStyle(
                              color: Colors.blueGrey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.blueGrey[200]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _noCoverWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.book_rounded, color: Colors.blueGrey[400], size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF1A1A2E) : Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.initialQuery != null
              ? '${widget.initialQuery} Books'
              : 'Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search bar + filters
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  onSubmitted: _searchBooks,
                  decoration: InputDecoration(
                    hintText: 'Search books, textbooks, subjects...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _books = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                _searchBooks(_searchController.text),
                          ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: _filters.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = filter);
                          if (_hasSearched) {
                            _searchBooks(_searchController.text);
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.blueGrey[800]
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blueGrey[700]),
                        SizedBox(height: 16),
                        Text(
                          'Searching books...',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.blueGrey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _searchBooks(_searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : !_hasSearched
                ? _buildStartState(isDark)
                : _books.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No books found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : Colors.blueGrey[700],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try switching to "All Time" filter',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _books.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildBookCard(_books[index], isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartState(bool isDark) {
    final suggestions = [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'History',
      'Computer Science',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'Search for any book or textbook',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.blueGrey[900],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Powered by Google Books',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          SizedBox(height: 20),
          Text(
            'Quick searches',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.blueGrey[600],
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = s;
                  _searchBooks(s);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2A2A3E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 14,
                        color: Colors.blueGrey[400],
                      ),
                      SizedBox(width: 6),
                      Text(
                        s,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.blueGrey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(dynamic book, bool isDark) {
    final info = book['volumeInfo'] ?? {};
    final title = info['title'] ?? 'Unknown Title';
    final authors =
        (info['authors'] as List?)?.take(2).join(', ') ?? 'Unknown Author';
    final publishedDate = info['publishedDate'] ?? '';
    final year = publishedDate.length >= 4
        ? publishedDate.substring(0, 4)
        : publishedDate;
    final thumbnail = info['imageLinks']?['thumbnail']?.toString().replaceAll(
      'http://',
      'https://',
    );
    final accessInfo = book['accessInfo'] ?? {};
    final viewability = accessInfo['viewability'] ?? 'NO_PAGES';
    final isPublicDomain = accessInfo['publicDomain'] ?? false;
    final canPreview = viewability == 'PARTIAL' || viewability == 'ALL_PAGES';
    final canDownload =
        isPublicDomain ||
        (accessInfo['epub']?['isAvailable'] ?? false) ||
        (accessInfo['pdf']?['isAvailable'] ?? false);

    return GestureDetector(
      onTap: () => _showBookDetails(Map<String, dynamic>.from(book)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2A2A3E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: thumbnail != null
                  ? Image.network(
                      thumbnail,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _noCoverWidget(70, 100),
                    )
                  : _noCoverWidget(70, 100),
            ),
            SizedBox(width: 14),

            // Book info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.blueGrey[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: Colors.blueGrey[400],
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authors,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (year.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.blueGrey[400],
                          ),
                          SizedBox(width: 4),
                          Text(
                            year,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (canPreview) _badge('Preview', Colors.blue),
                        if (canDownload) _badge('Download', Colors.green),
                        if (!canPreview && !canDownload)
                          _badge('Info Only', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
