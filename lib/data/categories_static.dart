class CategoryTile {
  final String id;          // bein, dazn, ...
  final String title;       // العنوان بالعربي
  final String assetIcon;   // مسار صورة الكرت
  final String playlistUrl; // رابط m3u على GitHub
  const CategoryTile({
    required this.id,
    required this.title,
    required this.assetIcon,
    required this.playlistUrl,
  });
}

const List<CategoryTile> kCategories = [
  CategoryTile(
    id: 'bein',
    title: 'باقة بي إن',
    assetIcon: 'assets/images/bein.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/bein.m3u',
  ),
  CategoryTile(
    id: 'dazn',
    title: 'باقة دازن',
    assetIcon: 'assets/images/DAZN.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/dazn.m3u',
  ),
  CategoryTile(
    id: 'espn',
    title: 'باقة ESPN',
    assetIcon: 'assets/images/ESPN.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/espn.m3u',
  ),
  CategoryTile(
    id: 'mbc',
    title: 'باقة MBC',
    assetIcon: 'assets/images/MBC.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/mbc.m3u',
  ),
  CategoryTile(
    id: 'seriaa',
    title: 'الدوري الإيطالي',
    assetIcon: 'assets/images/SERIA.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/SeriaA.m3u',
  ),
  CategoryTile(
    id: 'roshnleague',
    title: 'دوري روشن السعودي',
    assetIcon: 'assets/images/ROSNH.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/roshnleague.m3u',
  ),
  CategoryTile(
    id: 'premierleague',
    title: 'الدوري الإنجليزي الممتاز',
    assetIcon: 'assets/images/PREMIER LEAGUE.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/premierleague.m3u',
  ),
  CategoryTile(
    id: 'generalsports',
    title: 'قنوات رياضية عامة',
    assetIcon: 'assets/images/1.png', // ← مثل ما غيرتها
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/generalsports.m3u',
  ),
];
