import 'package:Taqyem/screens2/admin/admindashbord.dart';
import 'package:Taqyem/screens2/agent/Agentdashbord.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../login_signup/edit_user_screen.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({Key? key}) : super(key: key);

  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> with AutomaticKeepAliveClientMixin {
  // Variables
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _inactiveUsers = 0;
  String _selectedFilter = 'all';
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Stream controllers pour l'actualisation automatique
  late Stream<QuerySnapshot> _usersStream;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance
        .collection('Users')
        .orderBy('createdAt', descending: true)
        .snapshots();
    
    _searchController.addListener(_onSearchChanged);
    _getUsersStats();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Rafraîchir l'interface lors de la recherche
  }

  // Obtenir les statistiques des utilisateurs avec Stream pour mise à jour automatique
  Future<void> _getUsersStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Écouter les changements en temps réel
      FirebaseFirestore.instance.collection('Users').snapshots().listen((snapshot) {
        if (mounted) {
          int active = 0;
          int inactive = 0;
          
          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();
            if (data['isActive'] == true || data['status'] == 'active') {
              active++;
            } else {
              inactive++;
            }
          }
          
          setState(() {
            _totalUsers = snapshot.docs.length;
            _activeUsers = active;
            _inactiveUsers = inactive;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print("Erreur lors du comptage des utilisateurs: $e");
      setState(() => _isLoading = false);
    }
  }

  // Rafraîchissement manuel
  Future<void> _refreshData() async {
    setState(() {});
    await _getUsersStats();
    return Future.delayed(Duration(seconds: 1));
  }

  // Éditer utilisateur
  Future<void> editUser(BuildContext context, DocumentSnapshot user) async {
    bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(user: user),
      ),
    );

    if (shouldRefresh == true) {
      setState(() {});
      await _getUsersStats();
    }
  }

  // Supprimer utilisateur
  Future<void> deleteUser(String userId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(userId).delete();
        
        // Mise à jour automatique via le stream
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المستخدم بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف المستخدم: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Changer le statut de l'utilisateur
  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'isActive': !currentStatus,
        'status': !currentStatus ? 'active' : 'inactive',
        'lastStatusChange': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تغيير حالة المستخدم بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تغيير الحالة: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Afficher les détails de l'utilisateur
  void _showUserDetails(DocumentSnapshot user) {
    Map<String, dynamic> data = user.data() as Map<String, dynamic>;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'تفاصيل المستخدم',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildDetailRow(Icons.person, 'الاسم', data['name'] ?? 'لا يوجد'),
              _buildDetailRow(Icons.email, 'البريد الإلكتروني', data['email'] ?? 'لا يوجد'),
              _buildDetailRow(Icons.phone, 'رقم الهاتف', data['mobile'] ?? 'لا يوجد'),
              _buildDetailRow(Icons.badge, 'الدور', data['role'] ?? 'user'),
              _buildDetailRow(
                Icons.circle, 
                'الحالة', 
                data['isActive'] == true ? 'نشط' : 'غير نشط',
                color: data['isActive'] == true ? Colors.green : Colors.red,
              ),
              if (data['createdAt'] != null)
                _buildDetailRow(
                  Icons.calendar_today,
                  'تاريخ التسجيل',
                  _formatDate(data['createdAt']),
                ),
              if (data['lastLogin'] != null)
                _buildDetailRow(
                  Icons.access_time,
                  'آخر دخول',
                  _formatDate(data['lastLogin']),
                ),
            ],
          ),
        );
      },
    );
  }

  // Formatage de date
  String _formatDate(dynamic date) {
    if (date == null) return 'غير معروف';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
    }
    return date.toString();
  }

  // Ligne de détail
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Pour AutomaticKeepAliveClientMixin
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة المستخدمين',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color.fromRGBO(7, 82, 96, 1),
          elevation: 4,
          actions: [
            // Bouton de rafraîchissement
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
              tooltip: 'تحديث',
            ),
            
            // Compteur d'utilisateurs
            Container(
              margin: EdgeInsets.only(right: 8, left: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Text(
                      '$_totalUsers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  SizedBox(width: 4),
                  Text(
                    _totalUsers == 1 ? 'مستخدم' : 'مستخدمين',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          color: Color.fromRGBO(7, 82, 96, 1),
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // Cartes de statistiques avec animation
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'إجمالي المستخدمين',
                        _totalUsers,
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'نشط',
                        _activeUsers,
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'غير نشط',
                        _inactiveUsers,
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Barre de recherche avec bouton d'effacement
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث عن مستخدم...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              
              // Filtres
              Container(
                height: 50,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildAnimatedFilterChip('الكل', 'all', Icons.list),
                    _buildAnimatedFilterChip('نشط', 'active', Icons.check_circle),
                    _buildAnimatedFilterChip('غير نشط', 'inactive', Icons.cancel),
                  ],
                ),
              ),
              
              // Liste des utilisateurs avec StreamBuilder pour mise à jour automatique
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('جاري تحميل المستخدمين...'),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 60, color: Colors.red),
                            SizedBox(height: 16),
                            Text('خطأ في تحميل المستخدمين: ${snapshot.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'لا يوجد مستخدمين',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: Text('تحديث'),
                            ),
                          ],
                        ),
                      );
                    }

                    var users = snapshot.data!.docs;
                    
                    // Appliquer les filtres
                    var filteredUsers = users.where((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      
                      // Filtre par statut
                      if (_selectedFilter == 'active') {
                        if (data['isActive'] != true) return false;
                      } else if (_selectedFilter == 'inactive') {
                        if (data['isActive'] == true) return false;
                      }
                      
                      // Filtre par recherche
                      if (_searchController.text.isNotEmpty) {
                        String query = _searchController.text.toLowerCase().trim();
                        String name = data['name']?.toLowerCase() ?? '';
                        String email = data['email']?.toLowerCase() ?? '';
                        String mobile = data['mobile']?.toLowerCase() ?? '';
                        
                        return name.contains(query) || 
                               email.contains(query) || 
                               mobile.contains(query);
                      }
                      
                      return true;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج للبحث',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: Text('مسح البحث'),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        var user = filteredUsers[index];
                        Map<String, dynamic> data = user.data() as Map<String, dynamic>;
                        
                        String name = data['name'] ?? 'لا يوجد اسم';
                        String email = data['email'] ?? 'لا يوجد بريد';
                        String mobile = data['mobile'] ?? 'لا يوجد هاتف';
                        bool isActive = data['isActive'] == true;
                        String role = data['role'] ?? 'user';

                        return _buildAnimatedUserCard(
                          user: user,
                          data: data,
                          name: name,
                          email: email,
                          mobile: mobile,
                          isActive: isActive,
                          role: role,
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // // Bouton d'ajout d'utilisateur avec animation
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () {
        //     // Animation de clic
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text('سيتم إضافة مستخدم جديد قريباً'),
        //         duration: Duration(seconds: 2),
        //       ),
        //     );
        //   },
        //   icon: Icon(Icons.person_add),
        //   label: Text('إضافة مستخدم'),
        //   backgroundColor: Color.fromRGBO(7, 82, 96, 1),
        // ),
        
        // Bouton de rafraîchissement en bas (optionnel)
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // Carte de statistique animée
  Widget _buildAnimatedStatCard(String label, int value, IconData icon, Color color) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, double animation, child) {
        return Transform.scale(
          scale: animation,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 28),
                  SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      value.toString(),
                      key: Key(value.toString()),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Carte utilisateur animée
  Widget _buildAnimatedUserCard({
    required DocumentSnapshot user,
    required Map<String, dynamic> data,
    required String name,
    required String email,
    required String mobile,
    required bool isActive,
    required String role,
    required int index,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, double animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation)),
            child: Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showUserDetails(user),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar avec initiales
                          CircleAvatar(
                            backgroundColor: isActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Badge de statut
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive 
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive ? Icons.check_circle : Icons.cancel,
                                            size: 12,
                                            color: isActive ? Colors.green : Colors.red,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            isActive ? 'نشط' : 'غير نشط',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isActive ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Badge de rôle
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                            size: 12,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            role == 'admin' ? 'مدير' : 'مستخدم',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Menu des actions
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                editUser(context, user);
                              } else if (value == 'delete') {
                                deleteUser(user.id);
                              } else if (value == 'toggle') {
                                toggleUserStatus(user.id, isActive);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive ? Icons.block : Icons.check_circle,
                                      color: isActive ? Colors.orange : Colors.green,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(isActive ? 'تعطيل' : 'تفعيل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('حذف'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Informations supplémentaires
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    mobile,
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Chip de filtre animé
  Widget _buildAnimatedFilterChip(String label, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1),
      duration: Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: isSelected ? scale : 1,
          child: Padding(
            padding: EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  SizedBox(width: 4),
                  Text(label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Color.fromRGBO(7, 82, 96, 1),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 12,
              ),
              elevation: isSelected ? 4 : 1,
            ),
          ),
        );
      },
    );
  }
}