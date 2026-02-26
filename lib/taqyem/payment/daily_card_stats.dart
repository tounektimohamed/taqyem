class CardModel {
  final String id; // A, B, or C
  final String name;
  final int dailyLimit; // 14 مشترك
  final int maxDailyAmount; // 500 دينار تقريباً
  int currentCount;
  String? lastUsedDate;
  
  // الحقول الجديدة
  String? qrCodeUrl;    // رابط صورة QR Code
  String? ribNumber;     // رقم RIB
  String? bankName;      // اسم البنك (اختياري)

  CardModel({
    required this.id,
    required this.name,
    required this.dailyLimit,
    required this.maxDailyAmount,
    this.currentCount = 0,
    this.lastUsedDate,
    this.qrCodeUrl,
    this.ribNumber,
    this.bankName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dailyLimit': dailyLimit,
      'maxDailyAmount': maxDailyAmount,
      'currentCount': currentCount,
      'lastUsedDate': lastUsedDate,
      'qrCodeUrl': qrCodeUrl,
      'ribNumber': ribNumber,
      'bankName': bankName,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dailyLimit: map['dailyLimit'] ?? 14,
      maxDailyAmount: map['maxDailyAmount'] ?? 500,
      currentCount: map['currentCount'] ?? 0,
      lastUsedDate: map['lastUsedDate'],
      qrCodeUrl: map['qrCodeUrl'],
      ribNumber: map['ribNumber'],
      bankName: map['bankName'],
    );
  }

  bool get isAvailable => currentCount < dailyLimit;
  int get remainingSlots => dailyLimit - currentCount;
  bool get hasQRCode => qrCodeUrl != null && qrCodeUrl!.isNotEmpty;
  bool get hasRIB => ribNumber != null && ribNumber!.isNotEmpty;
}