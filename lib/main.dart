import 'dart:async';
import 'package:flutter/material.dart';

// ===== main =====
void main() => runApp(const StudyAlarmApp());

class StudyAlarmApp extends StatelessWidget {
  const StudyAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F5BFF),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ===== models/event.dart =====
enum Category { study, work, deadline }

extension CategoryX on Category {
  String get label => switch (this) {
        Category.study => 'Học',
        Category.work => 'Làm thêm',
        Category.deadline => 'Deadline',
      };

  Color get color => switch (this) {
        Category.study => const Color(0xFF2F5BFF),
        Category.work => const Color(0xFF12B886),
        Category.deadline => const Color(0xFFE5484D),
      };
}

enum Repeat { none, weekly, daily }

extension RepeatX on Repeat {
  String get label => switch (this) {
        Repeat.none => 'Không',
        Repeat.weekly => 'Hàng tuần',
        Repeat.daily => 'Hàng ngày',
      };
}

class TaskItem {
  final String text;
  bool done;
  TaskItem(this.text, {this.done = false});
}

class Event {
  final String id;
  String title;
  DateTime date;
  TimeOfDay start;
  TimeOfDay? end;
  Category category;
  Repeat repeat;
  int remindBefore; // phút
  String location;
  String note;
  List<TaskItem> tasks;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.start,
    this.end,
    this.category = Category.study,
    this.repeat = Repeat.none,
    this.remindBefore = 15,
    this.location = '',
    this.note = '',
    List<TaskItem>? tasks,
  }) : tasks = tasks ?? [];

  DateTime startOn(DateTime d) =>
      DateTime(d.year, d.month, d.day, start.hour, start.minute);
}

String two(int n) => n.toString().padLeft(2, '0');
String fmtTime(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

// ===== store.dart =====
class User {
  String name;
  String email;
  String password;
  String faculty;
  int year;
  User(this.name, this.email, this.password,
      {this.faculty = '', this.year = 1});
}

class AppSettings {
  int defaultRemind = 30;
  String ringtone = 'Sáng sớm';
  String dismiss = 'Vuốt để tắt';
  bool vibrate = true;
  bool ringOnSilent = false;
  bool googleSync = true;
}

/// Du lieu luu trong bo nho (chua co CSDL/backend).
class AppStore extends ChangeNotifier {
  AppStore._() {
    final now = DateTime.now();
    final tom = now.add(const Duration(days: 1));
    TimeOfDay t(int h, int m) => TimeOfDay(hour: h, minute: m);
    events.addAll([
      Event(id: '1', title: 'Lập trình thiết bị di động', date: now,
          start: t(13, 30), end: t(15, 0), category: Category.study,
          repeat: Repeat.weekly, remindBefore: 15, location: 'B4-302'),
      Event(id: '2', title: 'Ca làm quán cà phê', date: now,
          start: t(16, 0), end: t(20, 0), category: Category.work,
          remindBefore: 30),
      Event(id: '3', title: 'Ôn Vật lý đại cương', date: now,
          start: t(21, 0), category: Category.study, location: 'Tự học'),
      Event(id: '4', title: 'Nộp báo cáo Lập trình', date: now,
          start: t(23, 59), category: Category.deadline, remindBefore: 30,
          note: 'Nộp file PDF lên hệ thống LMS, đặt tên theo mẫu MSSV_HoTen.',
          tasks: [
            TaskItem('Viết phần mở đầu', done: true),
            TaskItem('Chạy thử và chụp kết quả', done: true),
            TaskItem('Kiểm tra trích dẫn'),
            TaskItem('Xuất PDF và nộp'),
          ]),
      Event(id: '5', title: 'Cấu trúc dữ liệu', date: tom,
          start: t(7, 30), end: t(10, 0), category: Category.study,
          location: 'A2-204'),
      Event(id: '6', title: 'Tiếng Anh chuyên ngành', date: tom,
          start: t(13, 0), end: t(15, 0), category: Category.study,
          location: 'C5 101'),
      Event(id: '7', title: 'Gia sư Toán lớp 9', date: tom,
          start: t(17, 30), end: t(19, 0), category: Category.work,
          location: 'Quận 10'),
      Event(id: '8', title: 'Nộp bài tập Xác suất', date: tom,
          start: t(23, 59), category: Category.deadline, remindBefore: 60),
    ]);
  }

  static final AppStore i = AppStore._();

  final List<User> users = [
    User('Nguyễn Văn Minh', 'sinhvien@ut.edu.vn', '123456',
        faculty: 'Khoa học Máy tính', year: 2),
  ];
  User? current;
  final List<Event> events = [];
  final AppSettings settings = AppSettings();
  int focusMinutes = 0; // cong them vao so lieu mau 12h40m

  // ---- Tai khoan ----
  bool login(String email, String pass) {
    for (final u in users) {
      if (u.email == email && u.password == pass) {
        current = u;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool register(String name, String email, String pass) {
    if (users.any((u) => u.email == email)) return false;
    final u = User(name, email, pass);
    users.add(u);
    current = u;
    notifyListeners();
    return true;
  }

  bool emailExists(String email) => users.any((u) => u.email == email);

  void logout() {
    current = null;
    notifyListeners();
  }

  void changed() => notifyListeners();

  // ---- Su kien ----
  bool _occurs(Event e, DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final base = DateTime(e.date.year, e.date.month, e.date.day);
    if (day.isBefore(base)) return false;
    return switch (e.repeat) {
      Repeat.none => day == base,
      Repeat.daily => true,
      Repeat.weekly => day.weekday == base.weekday,
    };
  }

  List<Event> eventsOn(DateTime day) {
    final list = events.where((e) => _occurs(e, day)).toList()
      ..sort((a, b) => (a.start.hour * 60 + a.start.minute)
          .compareTo(b.start.hour * 60 + b.start.minute));
    return list;
  }

  Event? byId(String id) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  }

  void add(Event e) {
    events.add(e);
    notifyListeners();
  }

  void remove(String id) {
    events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  int upcomingDeadlines() {
    final now = DateTime.now();
    return events
        .where((e) =>
            e.category == Category.deadline && e.startOn(e.date).isAfter(now))
        .length;
  }
}

// ===== screens/widgets.dart =====
const kBlue = Color(0xFF2F5BFF);
const kNavy = Color(0xFF0F1B33);
const kSoft = Color(0xFFF1F4FA);

const weekdayFull = [
  'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'
];

String longDate(DateTime d) =>
    '${weekdayFull[d.weekday - 1]}, ${d.day} tháng ${d.month}';

String untilText(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} PHÚT NỮA';
  return '${d.inHours} GIỜ ${d.inMinutes % 60} PHÚT NỮA';
}

String hm(int totalMinutes) => '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';

class EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool tinted;
  const EventTile(
      {super.key,
      required this.event,
      required this.onTap,
      this.tinted = false});

  String get _sub {
    if (event.location.isNotEmpty) return event.location;
    if (event.end != null) {
      return '${fmtTime(event.start)} – ${fmtTime(event.end!)}';
    }
    return event.category.label;
  }

  @override
  Widget build(BuildContext context) {
    final c = event.category.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tinted ? c.withValues(alpha: 0.12) : kSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(fmtTime(event.start),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(width: 10),
            Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_sub,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ===== screens/auth_screens.dart =====
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final ok =
        AppStore.i.register(_name.text.trim(), _email.text.trim(), _pass.text);
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email đã được dùng')));
      return;
    }
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email trường'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email không hợp lệ'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mật khẩu tối thiểu 6 ký tự'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
              validator: (v) => v != _pass.text ? 'Mật khẩu không khớp' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Đăng ký')),
          ]),
        ),
      ),
    );
  }
}

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final ok = AppStore.i.emailExists(_email.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Đã gửi liên kết đặt lại mật khẩu (mô phỏng)'
            : 'Email chưa đăng ký')));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text(
                'Nhập email trường đã đăng ký, chúng tôi sẽ gửi liên kết đặt lại mật khẩu.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email trường'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email không hợp lệ'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Gửi liên kết')),
          ]),
        ),
      ),
    );
  }
}

// ===== screens/login_screen.dart =====
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'sinhvien@ut.edu.vn');
  final _pass = TextEditingController(text: '123456');
  bool _hide = true;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (AppStore.i.login(_email.text.trim(), _pass.text)) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai email hoặc mật khẩu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: kBlue,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.alarm, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Chào mừng quay lại',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'Đăng nhập để đồng bộ lịch học và deadline của bạn.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email trường'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email không hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: TextButton(
                        onPressed: () => setState(() => _hide = !_hide),
                        child: Text(_hide ? 'Hiện' : 'Ẩn'),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mật khẩu tối thiểu 6 ký tự'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotScreen())),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Đăng nhập')),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                        child:
                            Text('hoặc', style: TextStyle(color: Colors.black54))),
                  ),
                  OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đăng nhập Google (mô phỏng)'))),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('Tiếp tục với Google'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: const Text('Đăng ký'),
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
  }
}

// ===== screens/shell.dart =====
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _i == 2 ? kNavy : null,
      body: SafeArea(
        child: IndexedStack(index: _i, children: const [
          TodayTab(),
          WeekTab(),
          FocusTab(),
          StatsTab(),
          ProfileTab(),
        ]),
      ),
      floatingActionButton: (_i == 0 || _i == 1)
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EventFormScreen())),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Tuần'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Tập trung'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Thống kê'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// ===== screens/today_tab.dart =====
class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final s = AppStore.i;
        final now = DateTime.now();
        final list = s.eventsOn(now);
        final upcoming =
            list.where((e) => e.startOn(now).isAfter(now)).toList();
        final next = upcoming.isEmpty ? null : upcoming.first;
        final name = s.current?.name ?? '';
        final first = name.trim().isEmpty ? '' : name.trim().split(' ').last;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(longDate(now), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text('Chào $first, hôm nay có ${list.length} việc',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (next == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: kSoft, borderRadius: BorderRadius.circular(16)),
                child: const Text('Hôm nay không còn việc nào sắp tới'),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AlarmScreen(event: next))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kBlue, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'SẮP TỚI · ${untilText(next.startOn(now).difference(now))}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                          next.location.isEmpty
                              ? next.title
                              : '${next.title} · ${next.location}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              next.end == null
                                  ? fmtTime(next.start)
                                  : '${fmtTime(next.start)} – ${fmtTime(next.end!)}',
                              style: const TextStyle(color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('Chuông ${next.remindBefore} phút trước',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text('HÔM NAY',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Chưa có việc. Nhấn + để thêm.')),
              ),
            for (final e in list)
              EventTile(
                event: e,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EventDetailScreen(id: e.id))),
              ),
          ],
        );
      },
    );
  }
}

// ===== screens/week_tab.dart =====
class WeekTab extends StatefulWidget {
  const WeekTab({super.key});
  @override
  State<WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends State<WeekTab> {
  DateTime _selected = DateTime.now();
  DateTime _weekStart = _monday(DateTime.now());

  static DateTime _monday(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _shift(int weeks) => setState(() {
        _weekStart = _weekStart.add(Duration(days: 7 * weeks));
        _selected = _weekStart;
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
        final list = AppStore.i.eventsOn(_selected);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(children: [
              Expanded(
                child: Text(
                    'Tuần ${days.first.day} – ${days.last.day}/${days.last.month}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left)),
              IconButton(
                  onPressed: () => _shift(1),
                  icon: const Icon(Icons.chevron_right)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selected = days[i]),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sameDay(days[i], _selected) ? kBlue : kSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Text(weekdayLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: sameDay(days[i], _selected)
                                    ? Colors.white
                                    : Colors.black54)),
                        const SizedBox(height: 4),
                        Text('${days[i].day}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sameDay(days[i], _selected)
                                    ? Colors.white
                                    : null)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Text(longDate(_selected).toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Không có sự kiện')),
              ),
            for (final e in list)
              EventTile(
                event: e,
                tinted: true,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EventDetailScreen(id: e.id))),
              ),
          ],
        );
      },
    );
  }
}

// ===== screens/event_form_screen.dart =====
class EventFormScreen extends StatefulWidget {
  final Event? event;
  const EventFormScreen({super.key, this.event});
  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _note;
  late DateTime _date;
  late TimeOfDay _start;
  TimeOfDay? _end;
  late Category _category;
  late Repeat _repeat;
  late int _remind;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _place = TextEditingController(text: e?.location ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
    _start = e?.start ?? const TimeOfDay(hour: 14, minute: 0);
    _end = e?.end;
    _category = e?.category ?? Category.study;
    _repeat = e?.repeat ?? Repeat.none;
    _remind = e?.remindBefore ?? AppStore.i.settings.defaultRemind;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
        context: context,
        initialTime: _end ?? TimeOfDay(hour: (_start.hour + 1) % 24, minute: _start.minute));
    if (t != null) setState(() => _end = t);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final e = widget.event;
    if (e == null) {
      AppStore.i.add(Event(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        date: _date,
        start: _start,
        end: _end,
        category: _category,
        repeat: _repeat,
        remindBefore: _remind,
        location: _place.text.trim(),
        note: _note.text.trim(),
      ));
    } else {
      e
        ..title = _title.text.trim()
        ..date = _date
        ..start = _start
        ..end = _end
        ..category = _category
        ..repeat = _repeat
        ..remindBefore = _remind
        ..location = _place.text.trim()
        ..note = _note.text.trim();
      AppStore.i.changed();
    }
    Navigator.pop(context);
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.event == null ? 'Thêm sự kiện' : 'Sửa sự kiện')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Tên sự kiện'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên sự kiện' : null,
            ),
            _label('Loại'),
            Wrap(spacing: 8, children: [
              for (final c in Category.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ]),
            _label('Thời gian'),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('${longDate(_date)} · ${fmtDate(_date)}'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: _pickStart,
                    child: Text('Bắt đầu ${fmtTime(_start)}')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                    onPressed: _pickEnd,
                    child: Text(
                        _end == null ? 'Kết thúc: không' : 'Kết thúc ${fmtTime(_end!)}')),
              ),
            ]),
            if (_end != null)
              TextButton(
                  onPressed: () => setState(() => _end = null),
                  child: const Text('Bỏ giờ kết thúc')),
            _label('Địa điểm'),
            TextFormField(
              controller: _place,
              decoration: const InputDecoration(hintText: 'Ví dụ: B4-302'),
            ),
            _label('Lặp lại'),
            Wrap(spacing: 8, children: [
              for (final r in Repeat.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _repeat == r,
                  onSelected: (_) => setState(() => _repeat = r),
                ),
            ]),
            _label('Chuông nhắc trước'),
            Wrap(spacing: 8, children: [
              for (final m in const [15, 30, 60])
                ChoiceChip(
                  label: Text(m == 60 ? '1 tiếng' : '$m phút'),
                  selected: _remind == m,
                  onSelected: (_) => setState(() => _remind = m),
                ),
            ]),
            _label('Ghi chú'),
            TextFormField(controller: _note, maxLines: 3),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Lưu sự kiện')),
          ]),
        ),
      ),
    );
  }
}

// ===== screens/event_detail_screen.dart =====
class EventDetailScreen extends StatelessWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sự kiện'),
        content: const Text('Bạn có chắc muốn xóa sự kiện này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppStore.i.remove(id);
      Navigator.pop(context);
    }
  }

  String _remaining(DateTime at) {
    final d = at.difference(DateTime.now());
    if (d.isNegative) return 'đã qua';
    if (d.inHours >= 24) return 'còn ${d.inDays} ngày ${d.inHours % 24} giờ';
    return 'còn ${d.inHours} giờ ${d.inMinutes % 60} phút';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final e = AppStore.i.byId(id);
        if (e == null) return const Scaffold(body: SizedBox());
        final at = e.startOn(e.date);
        final reminders = <int>[
          if (e.category == Category.deadline && e.remindBefore != 180) 180,
          e.remindBefore,
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quay lại'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EventFormScreen(event: e))),
                child: const Text('Sửa'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: e.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(e.category.label,
                      style: TextStyle(
                          color: e.category.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              Text(e.title,
                  style:
                      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  '${longDate(e.date)}, ${fmtTime(e.start)}'
                  '${e.end == null ? '' : ' – ${fmtTime(e.end!)}'}'
                  '${e.category == Category.deadline ? ' · ${_remaining(at)}' : ''}',
                  style: const TextStyle(color: Colors.black54)),
              if (e.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Địa điểm: ${e.location}',
                    style: const TextStyle(color: Colors.black54)),
              ],
              if (e.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kSoft, borderRadius: BorderRadius.circular(12)),
                  child: Text(e.note),
                ),
              ],
              if (e.tasks.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('VIỆC CẦN LÀM',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                for (final t in e.tasks)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: t.done,
                    title: Text(t.text,
                        style: TextStyle(
                            decoration:
                                t.done ? TextDecoration.lineThrough : null)),
                    onChanged: (v) {
                      t.done = v ?? false;
                      AppStore.i.changed();
                    },
                  ),
              ],
              const SizedBox(height: 20),
              const Text('NHẮC NHỞ',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              for (final m in reminders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm),
                  title: Text(m >= 60 ? '${m ~/ 60} tiếng trước' : '$m phút trước'),
                  subtitle: Text(
                      '${fmtTime(TimeOfDay.fromDateTime(at.subtract(Duration(minutes: m))))} chuông lớn'),
                ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => _delete(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE5484D),
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Xóa sự kiện'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===== screens/alarm_screen.dart =====
/// Man hinh chuong bao (mo phong, chua phat am thanh that).
class AlarmScreen extends StatelessWidget {
  final Event event;
  const AlarmScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white12, borderRadius: BorderRadius.circular(12)),
              child: Text(
                  event.category == Category.deadline
                      ? 'Sắp đến hạn nộp'
                      : 'Sắp đến giờ học',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            const SizedBox(height: 24),
            Text(fmtTime(now),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(event.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600)),
            Text(
                'Bắt đầu lúc ${fmtTime(event.start)}'
                '${event.location.isEmpty ? '' : ' · ${event.location}'}',
                style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kBlue, width: 4),
              ),
              child: const Icon(Icons.alarm, color: Colors.white, size: 56),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                  backgroundColor: kBlue,
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Tắt chuông'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sẽ nhắc lại sau 10 phút')));
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Nhắc lại sau 10 phút'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ===== screens/focus_tab.dart =====
class FocusTab extends StatefulWidget {
  const FocusTab({super.key});
  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> {
  int _minutes = 25;
  int _left = 25 * 60;
  int _session = 1;
  bool _running = false;
  Timer? _timer;

  void _setMinutes(int m) {
    if (_running) return;
    setState(() {
      _minutes = m;
      _left = m * 60;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _left--);
        if (_left <= 0) _complete();
      });
    }
  }

  void _complete() {
    _timer?.cancel();
    AppStore.i.focusMinutes += _minutes;
    AppStore.i.changed();
    setState(() {
      _running = false;
      if (_session < 4) _session++;
      _left = _minutes * 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hết giờ! Nghỉ 5 phút nhé.')));
  }

  void _finish() {
    _timer?.cancel();
    final done = (_minutes * 60 - _left) ~/ 60;
    AppStore.i.focusMinutes += done;
    AppStore.i.changed();
    setState(() {
      _running = false;
      _session = 1;
      _left = _minutes * 60;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _left / (_minutes * 60);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('Tập trung',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('Phiên học Pomodoro',
            style: TextStyle(color: Colors.white70)),
        const Spacer(),
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                color: kBlue,
                backgroundColor: Colors.white12,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${two(_left ~/ 60)}:${two(_left % 60)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold)),
              Text('Phiên $_session / 4',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final m in const [25, 40, 50])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('$m phút'),
                selected: _minutes == m,
                onSelected: (_) => _setMinutes(m),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        const Text('Nghỉ 5 phút sau mỗi phiên. Chuông sẽ báo khi hết giờ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        FilledButton(
          onPressed: _toggle,
          style: FilledButton.styleFrom(
              backgroundColor: kBlue, minimumSize: const Size.fromHeight(52)),
          child: Text(_running ? 'Tạm dừng' : 'Bắt đầu'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _finish,
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size.fromHeight(52)),
          child: const Text('Kết thúc phiên'),
        ),
      ]),
    );
  }
}

// ===== screens/stats_tab.dart =====
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  // So lieu mau (gio hoc moi ngay T2..CN)
  static const _daily = [4.0, 6.5, 3.0, 8.0, 3.5, 1.5, 1.0];

  Widget _card(String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kSoft, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(small,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      );

  Widget _bar(String label, String value, double frac, Color c) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label),
            Text(value, style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: frac, minHeight: 8, color: c, backgroundColor: kSoft),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final focus = 760 + AppStore.i.focusMinutes; // 12h40m + phien moi
        final today = DateTime.now().weekday - 1;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Thống kê tuần',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Số liệu mẫu', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Row(children: [
              _card(hm(focus), 'Giờ tập trung'),
              const SizedBox(width: 8),
              _card('86%', 'Đúng giờ'),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _card('5 ngày', 'Chuỗi đúng giờ'),
              const SizedBox(width: 8),
              _card('${AppStore.i.upcomingDeadlines()}', 'Deadline sắp tới'),
            ]),
            const SizedBox(height: 20),
            const Text('GIỜ HỌC MỖI NGÀY',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        width: 28,
                        height: _daily[i] * 11,
                        decoration: BoxDecoration(
                          color: i == today ? kBlue : const Color(0xFFD9E0F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(weekdayLabels[i], style: const TextStyle(fontSize: 11)),
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('THEO LOẠI',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            _bar('Học', '9h 10m', 0.72, const Color(0xFF2F5BFF)),
            _bar('Làm thêm', '3h 30m', 0.28, const Color(0xFF12B886)),
          ],
        );
      },
    );
  }
}

// ===== screens/profile_tab.dart =====
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _edit(BuildContext context, User u) async {
    final name = TextEditingController(text: u.name);
    final faculty = TextEditingController(text: u.faculty);
    final year = TextEditingController(text: '${u.year}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin cá nhân'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Họ và tên')),
          const SizedBox(height: 12),
          TextField(
              controller: faculty,
              decoration: const InputDecoration(labelText: 'Khoa')),
          const SizedBox(height: 12),
          TextField(
              controller: year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Năm')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      u.name = name.text.trim();
      u.faculty = faculty.text.trim();
      u.year = int.tryParse(year.text) ?? u.year;
      AppStore.i.changed();
    }
  }

  Widget _stat(String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kSoft, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(small,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.i,
      builder: (context, _) {
        final u = AppStore.i.current;
        if (u == null) return const SizedBox();
        final s = AppStore.i.settings;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kSoft,
                child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 22, color: kBlue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${u.faculty} Năm ${u.year}'.trim(),
                      style: const TextStyle(color: Colors.black54)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _stat('5 ngày', 'Chuỗi hiện tại'),
              const SizedBox(width: 8),
              _stat('21 ngày', 'Chuỗi dài nhất'),
            ]),
            const SizedBox(height: 16),
            const Text('TÀI KHOẢN',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thông tin cá nhân'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _edit(context, u),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đồng bộ với Google Calendar'),
              value: s.googleSync,
              onChanged: (v) {
                s.googleSync = v;
                AppStore.i.changed();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thời khóa biểu của trường'),
              trailing: const Text('Nhập file',
                  style: TextStyle(color: Colors.black54)),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nhập file (chưa hỗ trợ)'))),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Ngôn ngữ'),
              trailing: Text('Tiếng Việt', style: TextStyle(color: Colors.black54)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cài đặt nhắc nhở'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                AppStore.i.logout();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE5484D),
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}

// ===== screens/settings_screen.dart =====
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final s = AppStore.i.settings;

  Widget _drop(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
        onChanged: (v) => setState(() => onChanged(v!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt nhắc nhở')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Nhắc trước mặc định'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final m in const [15, 30, 60])
              ChoiceChip(
                label: Text(m == 60 ? '1 tiếng' : '$m phút'),
                selected: s.defaultRemind == m,
                onSelected: (_) => setState(() => s.defaultRemind = m),
              ),
          ]),
          const SizedBox(height: 8),
          _drop('Nhạc chuông', s.ringtone, const ['Sáng sớm', 'Chuông cổ điển', 'Sóng biển'],
              (v) => s.ringtone = v),
          _drop('Cách tắt chuông', s.dismiss,
              const ['Vuốt để tắt', 'Giải toán', 'Bấm nút'], (v) => s.dismiss = v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rung'),
            value: s.vibrate,
            onChanged: (v) => setState(() => s.vibrate = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc cả khi bật Im lặng'),
            value: s.ringOnSilent,
            onChanged: (v) => setState(() => s.ringOnSilent = v),
          ),
          const SizedBox(height: 16),
          const Text('CHUỖI NGÀY ĐÚNG GIỜ',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: i < 5 ? kBlue : kSoft,
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          const Text('Tắt chuông và có mặt đúng giờ để giữ chuỗi.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
