import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      final url = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=20&fields=key,title,author_name,first_publish_year,cover_i,subject',
      );

      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _books = data['docs'] ?? [];
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

  void _showBookDetails(Map<String, dynamic> book) {
    final title = book['title'] ?? 'Unknown Title';
    final authors =
        (book['author_name'] as List?)?.join(', ') ?? 'Unknown Author';
    final year = book['first_publish_year']?.toString() ?? 'Unknown Year';
    final coverId = book['cover_i'];
    final subjects =
        (book['subject'] as List?)?.take(5).join(', ') ?? 'No subjects listed';
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-L.jpg'
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: coverUrl != null
                                ? Image.network(
                                    coverUrl,
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
                                    fontSize: 18,
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
                                      size: 14,
                                      color: Colors.blueGrey[400],
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        authors,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueGrey[500],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: Colors.blueGrey[400],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'First published $year',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Divider(
                        color: isDark ? Colors.white12 : Colors.grey[200],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Subjects',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.blueGrey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        subjects,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.blueGrey[600],
                          height: 1.5,
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
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              onSubmitted: _searchBooks,
              decoration: InputDecoration(
                hintText: 'Search books, textbooks, subjects...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
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
                        icon: Icon(Icons.search_rounded, color: Colors.white70),
                        onPressed: () => _searchBooks(_searchController.text),
                      ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
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
                          'Try a different search term',
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
            'Powered by Open Library',
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
    final title = book['title'] ?? 'Unknown Title';
    final authors =
        (book['author_name'] as List?)?.take(2).join(', ') ?? 'Unknown Author';
    final year = book['first_publish_year']?.toString() ?? '';
    final coverId = book['cover_i'];
    final coverUrl = coverId != null
        ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
        : null;

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
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
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
                padding: EdgeInsets.symmetric(vertical: 14),
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
                    SizedBox(height: 6),
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
                            size: 13,
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
