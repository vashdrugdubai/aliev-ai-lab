import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://elqhycrrolgoikrseegt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVscWh5Y3Jyb2xnb2lrcnNlZWd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NDQwNTQsImV4cCI6MjA5NjMyMDA1NH0.iBADQdVHFvrAFZbIhbrGVXXAy1MkpJTIWR1tVgrVRHM',
  );
  runApp(const KvartiradxbApp());
}

final supabase = Supabase.instance.client;

class KvartiradxbApp extends StatelessWidget {
  const KvartiradxbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'КВАРТИРА ОАЭ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B4B6F),
          primary: const Color(0xFF2B4B6F),
        ),
        useMaterial3: true,
      ),
      home: const MainNav(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    PostScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home_outlined, 'label': 'Главная'},
    {'icon': Icons.map_outlined, 'label': 'Карта'},
    {'icon': Icons.add_circle, 'label': 'Подать'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Чат'},
    {'icon': Icons.person_outline, 'label': 'Профиль'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDDE4ED), width: 0.5)),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = _selectedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isActive ? const Color(0xFF2B4B6F) : const Color(0xFFAABBCC),
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? const Color(0xFF2B4B6F) : const Color(0xFFAABBCC),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ГЛАВНАЯ
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'Все';
  final List<String> _filters = ['Все', 'Комната', 'Койко-место', 'Квартира'];
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final data = await supabase
          .from('listings')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Ошибка загрузки объявлений: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredListings {
    var list = _listings;
    if (_selectedFilter != 'Все') {
      list = list.where((l) => l['type'] == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) {
        final location = (l['location'] ?? '').toString().toLowerCase();
        final type = (l['type'] ?? '').toString().toLowerCase();
        final metro = (l['metro'] ?? '').toString().toLowerCase();
        final desc = (l['description'] ?? '').toString().toLowerCase();
        return location.contains(q) || type.contains(q) || metro.contains(q) || desc.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2B4B6F)))
                : RefreshIndicator(
                    onRefresh: _loadListings,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 10),
                          child: Text('Свежие объявления',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF223344))),
                        ),
                        ..._filteredListings
                            .map((listing) => _buildCard(listing)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
        ),
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(children: [
                  TextSpan(
                      text: 'КВАРТИРА',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  TextSpan(
                      text: ' ОАЭ',
                      style: TextStyle(
                          color: Color(0xFF7EB8E8),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                ]),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Уведомления — скоро')),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Найди жильё в Дубае',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.search, color: Color(0xFF2B4B6F), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF223344)),
                  decoration: const InputDecoration(
                    hintText: 'Район, метро, билдинг...',
                    hintStyle: TextStyle(color: Color(0xFFAABBCC), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close, color: Color(0xFFAABBCC), size: 18),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final isActive = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2B4B6F)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isActive
                          ? const Color(0xFF2B4B6F)
                          : const Color(0xFFDDE4ED)),
                ),
                child: Text(filter,
                    style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF556677))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> listing) {
    final tags =
        (listing['tags'] as List?)?.cast<String>() ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListingDetailScreen(listing: listing),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFDDE4ED), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(
              color: Color(0xFF2B4B6F),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.apartment,
                        color: Colors.white24, size: 50)),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF7EB8E8),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(listing['type'] ?? '',
                        style: const TextStyle(
                            color: Color(0xFF1a3a5c),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                if (listing['metro'] != null)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.train,
                            color: Color(0xFF7EB8E8), size: 12),
                        const SizedBox(width: 4),
                        Text(listing['metro'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: '${listing['price']} AED',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1a3a5c))),
                        const TextSpan(
                            text: ' / месяц',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF889aaa))),
                      ]),
                    ),
                    const Icon(Icons.favorite_border,
                        color: Color(0xFFDDE4ED), size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(listing['location'] ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF667788))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius:
                                    BorderRadius.circular(6)),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2B4B6F))),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFEEF1F5)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE3EEF8),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(
                            listing['owner_initials'] ?? '?',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B4B6F)))),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing['owner_name'] ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF445566))),
                      if (listing['verified'] == true)
                        const Row(children: [
                          Icon(Icons.check_circle,
                              size: 10, color: Color(0xFF2B4B6F)),
                          SizedBox(width: 2),
                          Text('Верифицирован',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF2B4B6F))),
                        ]),
                    ],
                  ),
                ]),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.chat,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2B4B6F),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Написать',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

// ─────────────────────────────────────────────
// ДЕТАЛИ ОБЪЯВЛЕНИЯ
// ─────────────────────────────────────────────
class ListingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final tags = (listing['tags'] as List?)?.cast<String>() ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2B4B6F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.apartment, color: Colors.white24, size: 80),
                    ),
                    Positioned(
                      top: 100, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7EB8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(listing['type'] ?? '',
                            style: const TextStyle(
                                color: Color(0xFF1a3a5c),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '${listing['price']} AED',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1a3a5c)),
                          ),
                          const TextSpan(
                            text: ' / месяц',
                            style: TextStyle(fontSize: 14, color: Color(0xFF889aaa)),
                          ),
                        ]),
                      ),
                      const Icon(Icons.favorite_border, color: Color(0xFF2B4B6F), size: 26),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF2B4B6F), size: 16),
                      const SizedBox(width: 4),
                      Text(listing['location'] ?? '',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF667788))),
                    ],
                  ),
                  if (listing['metro'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.train, color: Color(0xFF2B4B6F), size: 16),
                        const SizedBox(width: 4),
                        Text(listing['metro'],
                            style: const TextStyle(fontSize: 14, color: Color(0xFF667788))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EEF8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF2B4B6F))),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (listing['description'] != null) ...[
                    const Text('Описание',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF223344))),
                    const SizedBox(height: 8),
                    Text(listing['description'],
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF445566),
                            height: 1.5)),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDDE4ED)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3EEF8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              listing['owner_initials'] ?? '?',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2B4B6F)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(listing['owner_name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF223344))),
                            if (listing['verified'] == true)
                              const Row(children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: Color(0xFF2B4B6F)),
                                SizedBox(width: 4),
                                Text('Верифицирован',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF2B4B6F))),
                              ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Позвонить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B4B6F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// КАРТА
// ─────────────────────────────────────────────
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 20),
            child: const Row(
              children: [
                Text('Карта',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 80, color: Color(0xFF2B4B6F)),
                  const SizedBox(height: 16),
                  const Text('Карта скоро появится',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B4B6F))),
                  const SizedBox(height: 8),
                  Text('Будут показаны все объявления на карте Дубая',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ПОДАТЬ ОБЪЯВЛЕНИЕ
// ─────────────────────────────────────────────
class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  String _selectedType = 'Комната';
  final List<String> _types = ['Комната', 'Койко-место', 'Квартира'];
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  Future<void> _submit() async {
    if (_titleController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await supabase.from('listings').insert({
        'title': _titleController.text,
        'type': _selectedType,
        'location': _locationController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'description': _descController.text,
        'owner_name': 'Пользователь',
        'owner_initials': 'П',
        'verified': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Объявление опубликовано!'),
              backgroundColor: Color(0xFF2B4B6F)),
        );
        _titleController.clear();
        _locationController.clear();
        _priceController.clear();
        _descController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 20),
            child: const Row(
              children: [
                Text('Подать объявление',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Тип жилья'),
                  Wrap(
                    spacing: 8,
                    children: _types.map((t) {
                      final isActive = _selectedType == t;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedType = t),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF2B4B6F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isActive
                                    ? const Color(0xFF2B4B6F)
                                    : const Color(0xFFDDE4ED)),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF556677))),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _label('Заголовок *'),
                  _field(_titleController,
                      'Пример: Комната в Deira, все удобства'),
                  const SizedBox(height: 12),
                  _label('Район / Адрес *'),
                  _field(_locationController,
                      'Пример: Deira, Al Rigga'),
                  const SizedBox(height: 12),
                  _label('Цена (AED / месяц) *'),
                  _field(_priceController, 'Пример: 2500',
                      isNumber: true),
                  const SizedBox(height: 12),
                  _label('Описание'),
                  _field(_descController,
                      'Расскажите подробнее о жилье...',
                      maxLines: 4),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4B6F),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Опубликовать объявление',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF445566))),
      );

  Widget _field(TextEditingController controller, String hint,
      {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4ED)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFAABBCC), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ЧАТ
// ─────────────────────────────────────────────
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 20),
            child: const Row(
              children: [
                Text('Сообщения',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 80, color: Color(0xFF2B4B6F)),
                  const SizedBox(height: 16),
                  const Text('Чат скоро появится',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B4B6F))),
                  const SizedBox(height: 8),
                  Text('Здесь будут ваши переписки с арендодателями',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ПРОФИЛЬ
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final StreamSubscription<AuthState> _authSub;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = supabase.auth.currentUser;
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _user = data.session?.user);
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  String _getInitials() {
    final email = _user?.email ?? '';
    if (email.isNotEmpty) return email.substring(0, 2).toUpperCase();
    final phone = _user?.phone ?? '';
    if (phone.length >= 4) return phone.substring(phone.length - 4);
    return '?';
  }

  String _getDisplayName() {
    final email = _user?.email ?? '';
    if (email.isNotEmpty) return email;
    return _user?.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 30),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text('Профиль',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: isLoggedIn
                      ? Center(
                          child: Text(
                                    _getInitials(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                        )
                      : const Icon(Icons.person,
                          color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  isLoggedIn ? _getDisplayName() : 'Войдите в аккаунт',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                if (isLoggedIn) ...[
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF7EB8E8), size: 14),
                      SizedBox(width: 4),
                      Text('Номер подтверждён',
                          style: TextStyle(
                              color: Color(0xFF7EB8E8), fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (!isLoggedIn)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PhoneAuthScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B4B6F),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                            'Войти через номер телефона',
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  if (isLoggedIn) ...[
                    _menuItem(Icons.home_outlined, 'Мои объявления', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Мои объявления — скоро')),
                      );
                    }),
                    _menuItem(Icons.favorite_border, 'Избранное', onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Избранное — скоро')),
                      );
                    }),
                  ],
                  _menuItem(Icons.calculate_outlined,
                      'Калькулятор (30% от зарплаты)', onTap: () => _showCalculator()),
                  _menuItem(Icons.info_outline, 'О приложении', onTap: () => _showAbout()),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Выйти из аккаунта'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          side: BorderSide(color: Colors.red[200]!),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculator() {
    final salaryController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          double? salary = double.tryParse(salaryController.text);
          double? budget = salary != null ? salary * 0.3 : null;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              top: 24, left: 24, right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Калькулятор жилья',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF223344))),
                const SizedBox(height: 6),
                const Text('30% от зарплаты — рекомендуемый бюджет на аренду',
                    style: TextStyle(fontSize: 13, color: Color(0xFF889aaa))),
                const SizedBox(height: 20),
                const Text('Ваша зарплата (AED/месяц)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF445566))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE4ED)),
                  ),
                  child: TextField(
                    controller: salaryController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Например: 8000',
                      hintStyle: TextStyle(color: Color(0xFFAABBCC)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      suffixText: 'AED',
                      suffixStyle: TextStyle(color: Color(0xFF889aaa)),
                    ),
                  ),
                ),
                if (budget != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EEF8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('Рекомендуемый бюджет на жильё',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF445566))),
                        const SizedBox(height: 6),
                        Text('${budget.toStringAsFixed(0)} AED / месяц',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2B4B6F))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'КВАРТИРА',
                style: TextStyle(
                    color: Color(0xFF2B4B6F),
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            TextSpan(
                text: ' ОАЭ',
                style: TextStyle(
                    color: Color(0xFF7EB8E8),
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        content: const Text(
          'Приложение для поиска комнат, койко-мест и квартир в Дубае.\n\nСоздано специально для граждан СНГ и русскоязычного сообщества ОАЭ.\n\nВерсия 1.0.0',
          style: TextStyle(fontSize: 14, color: Color(0xFF445566), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF2B4B6F), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFFE3EEF8),
          highlightColor: const Color(0xFFE3EEF8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE4ED)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2B4B6F), size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF334455))),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFAABBCC), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ЭКРАН ВХОДА — EMAIL
// ─────────────────────────────────────────────
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный email')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(contact: email, isEmail: true)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Войти',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                      'Введите email — пришлём код подтверждения',
                      style: TextStyle(
                          color: Color(0xFFAAD4F5), fontSize: 14)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('Email',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF445566))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE4ED)),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF223344)),
                      decoration: const InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: TextStyle(color: Color(0xFFAABBCC)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.email_outlined,
                            color: Color(0xFF2B4B6F)),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4B6F),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Получить код',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Отправим письмо с 6-значным кодом.\nБесплатно, без SMS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF889aaa)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ЭКРАН ВХОДА — ТЕЛЕФОН
// ─────────────────────────────────────────────
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+971';
  bool _loading = false;

  final List<Map<String, String>> _countries = const [
    {'code': '+971', 'flag': '🇦🇪', 'name': 'ОАЭ'},
    {'code': '+7',   'flag': '🇷🇺', 'name': 'Россия'},
    {'code': '+380', 'flag': '🇺🇦', 'name': 'Украина'},
    {'code': '+996', 'flag': '🇰🇬', 'name': 'Кыргызстан'},
    {'code': '+998', 'flag': '🇺🇿', 'name': 'Узбекистан'},
    {'code': '+992', 'flag': '🇹🇯', 'name': 'Таджикистан'},
    {'code': '+994', 'flag': '🇦🇿', 'name': 'Азербайджан'},
    {'code': '+374', 'flag': '🇦🇲', 'name': 'Армения'},
    {'code': '+995', 'flag': '🇬🇪', 'name': 'Грузия'},
    {'code': '+1',   'flag': '🇺🇸', 'name': 'США / Канада'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final local = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (local.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }
    final fullPhone = '$_countryCode$local';
    setState(() => _loading = true);
    try {
      await supabase.auth.signInWithOtp(phone: fullPhone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OtpScreen(contact: fullPhone, isEmail: false)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _countries.firstWhere(
        (c) => c['code'] == _countryCode,
        orElse: () => _countries.first);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Войти',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Введите номер — пришлём SMS с кодом',
                      style: TextStyle(
                          color: Color(0xFFAAD4F5), fontSize: 14)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('Страна',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF445566))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE4ED)),
                    ),
                    child: DropdownButton<String>(
                      value: _countryCode,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (val) => setState(() => _countryCode = val!),
                      items: _countries.map((c) {
                        return DropdownMenuItem(
                          value: c['code'],
                          child: Text(
                              '${c['flag']}  ${c['name']}  (${c['code']})',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Номер телефона',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF445566))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE4ED)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                                right: BorderSide(color: Color(0xFFDDE4ED))),
                          ),
                          child: Text(
                            '${selectedCountry['flag']}  ${selectedCountry['code']}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B4B6F)),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                                fontSize: 16, color: Color(0xFF223344)),
                            decoration: const InputDecoration(
                              hintText: '50 123 4567',
                              hintStyle:
                                  TextStyle(color: Color(0xFFAABBCC)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4B6F),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Получить код',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Отправим SMS с кодом подтверждения.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF889aaa)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ЭКРАН OTP
// ─────────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String contact;
  final bool isEmail;
  const OtpScreen({super.key, required this.contact, this.isEmail = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 6-значный код')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (widget.isEmail) {
        await supabase.auth.verifyOTP(
          email: widget.contact,
          token: otp,
          type: OtpType.email,
        );
      } else {
        await supabase.auth.verifyOTP(
          phone: widget.contact,
          token: otp,
          type: OtpType.sms,
        );
      }
      if (mounted) {
        // Закрываем оба экрана (PhoneAuth + OTP), возвращаемся к ProfileScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Неверный код. Проверьте SMS и попробуйте снова.')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      if (widget.isEmail) {
        await supabase.auth.signInWithOtp(email: widget.contact);
      } else {
        await supabase.auth.signInWithOtp(phone: widget.contact);
      }
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Код отправлен повторно'),
              backgroundColor: Color(0xFF2B4B6F)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    if (mounted) setState(() => _resending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B4B6F), Color(0xFF1a3a5c)],
              ),
            ),
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Подтверждение',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Код отправлен на ${widget.contact}',
                      style: const TextStyle(
                          color: Color(0xFFAAD4F5), fontSize: 14)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('Код из SMS',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF445566))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFDDE4ED)),
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 14,
                          color: Color(0xFF2B4B6F)),
                      decoration: const InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: TextStyle(
                            color: Color(0xFFDDE4ED),
                            fontSize: 22,
                            letterSpacing: 10),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4B6F),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                          : const Text('Подтвердить',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _countdown > 0
                        ? Text(
                            'Отправить повторно через ${_countdown}с',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF889aaa)),
                          )
                        : GestureDetector(
                            onTap: _resending ? null : _resend,
                            child: Text(
                              _resending
                                  ? 'Отправка...'
                                  : 'Отправить код повторно',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2B4B6F),
                                  fontWeight: FontWeight.w600),
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
  }
}
