/// State Management — Store Pattern + Provided Demo
///
/// Demonstrates:
///   1. Pattern B — "Store" class: plain Dart class with signal fields + actions.
///   2. [Provided<T>] — per-subtree DI; each task tile reads its own [TaskStore]
///      from the context instead of receiving it via constructor.
///   3. [AppStore] — a root singleton holder (the AppRepository pattern).
///
/// Intentionally uses NO StatefulWidget, NO setState, NO Provider, NO Consumer.
import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ── Domain ────────────────────────────────────────────────────────────────────

class Task {
  final String id;
  final String title;

  const Task({required this.id, required this.title});

  Task copyWith({String? title}) => Task(id: id, title: title ?? this.title);
}

// ── Store ─────────────────────────────────────────────────────────────────────

/// Feature store — holds state + actions for one task list.
///
/// Plain Dart class: no base class, no registry, no ref needed.
/// Expose [Signal] fields directly so widgets can `.watch` them.
class TaskStore {
  TaskStore(String label) : _label = label;

  final String _label;
  String get label => _label;

  /// The task list — the source of truth for this store.
  final tasks = signal<List<Task>>(const []);

  /// Derived stat: done count. Updates automatically.
  late final doneCount = computed<int>(
    () => tasks.value.where((t) => (t as _TaskData)._done).length,
  );

  /// Total count — derived from the same signal.
  late final totalCount = computed<int>(() => tasks.value.length);

  /// Draft text for the add-task field — a signal so the button can read it.
  final addDraft = signal<String>('');

  int _nextId = 1;

  void addTask(String title) {
    if (title.trim().isEmpty) return;
    final id = 'task-${_nextId++}';
    tasks.update((list) => [...list, _TaskData(id: id, title: title.trim())]);
  }

  void toggleDone(String id) {
    tasks.update(
      (list) => list.map((t) {
        if (t.id != id) return t;
        return _TaskData(
          id: t.id,
          title: t.title,
          done: !(t as _TaskData)._done,
        );
      }).toList(),
    );
  }

  void removeTask(String id) {
    tasks.update((list) => list.where((t) => t.id != id).toList());
  }

  void dispose() {
    tasks.dispose();
    doneCount.dispose();
    totalCount.dispose();
    addDraft.dispose();
  }
}

/// Internal mutable task — extends [Task] so the public type stays clean.
class _TaskData extends Task {
  final bool _done;

  const _TaskData({required super.id, required super.title, bool done = false})
      : _done = done;
}

extension _TaskDone on Task {
  bool get isDone => (this as _TaskData)._done;
}

// ── App-level singleton ───────────────────────────────────────────────────────

/// Root state holder — holds multiple stores.
/// In a real app this is your AppRepository.
class AppStore {
  AppStore._();

  static final workTasks = TaskStore('Work');
  static final personalTasks = TaskStore('Personal');

  /// App-wide theme mode — a bare top-level signal on the holder.
  static final themeMode = signal<String>(
      playgroundPalette.brightness == Brightness.dark ? 'dark' : 'light');
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StateStoreDemo extends StatelessWidget {
  const StateStoreDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppStore.themeMode.watch(context);
    final isDark = theme == 'dark';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'State — Store + Provided',
          style: TextStyle(
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        actions: [
          // Theme toggle writes a top-level signal — no setState
          IconButton(
            icon: Icon(
              isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
            ),
            onPressed: () {
              AppStore.themeMode.update((m) => m == 'dark' ? 'light' : 'dark');
            },
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16,
              isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16, 16, 16),
          children: [
            _PatternBExplainer(isDark: isDark),
            const SizedBox(height: 20),
            // Each _TaskListPanel wraps its store in Provided<TaskStore>
            // so its children can read it without prop-drilling.
            Provided<TaskStore>(
              value: AppStore.workTasks,
              child: const _TaskListPanel(),
            ),
            const SizedBox(height: 16),
            Provided<TaskStore>(
              value: AppStore.personalTasks,
              child: const _TaskListPanel(),
            ),
            const SizedBox(height: 24),
            _ProvidedExplainer(isDark: isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Task list panel ───────────────────────────────────────────────────────────

/// Reads its [TaskStore] from [Provided] — no constructor parameter needed.
class _TaskListPanel extends StatefulWidget {
  const _TaskListPanel();

  @override
  State<_TaskListPanel> createState() => _TaskListPanelState();
}

class _TaskListPanelState extends State<_TaskListPanel> {
  /// Owns the add-row field so Add / submit can clear the native text.
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reads the nearest Provided<TaskStore> ancestor.
    final store = Provided.of<TaskStore>(context);
    final tasks = store.tasks.watch(context);
    final done = store.doneCount.watch(context);
    final total = store.totalCount.watch(context);
    final isDark = AppStore.themeMode.watch(context) == 'dark';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    store.label,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$done / $total done',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6C6C70),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Task rows ────────────────────────────────────────────────
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                'No tasks yet.',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6C6C70),
                    fontSize: 14),
              ),
            )
          else
            ...tasks.map(
              (t) => Provided<TaskStore>(
                value: store, // pass same store deeper
                child: _TaskRow(task: t),
              ),
            ),

          // ── Add row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      controller: _draft,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF000000),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write task title…',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => store.addDraft.value = v,
                      onSubmitted: (v) {
                        store.addTask(v);
                        store.addDraft.value = '';
                        _draft.clear();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Button(
                  variant: ButtonVariant.bordered,
                  title: 'Add',
                  onPressed: () {
                    store.addTask(store.addDraft.value);
                    store.addDraft.value = '';
                    _draft.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────

/// Each tile reads its [TaskStore] via [Provided.of] — classic per-subtree DI.
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final store = Provided.of<TaskStore>(context);
    final isDark = AppStore.themeMode.watch(context) == 'dark';

    return GestureDetector(
      onTap: () => store.toggleDone(task.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: task.isDone,
              onChanged: (_) => store.toggleDone(task.id),
              activeColor: const Color(0xFF30D158),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: task.isDone
                      ? kTextSecondary
                      : (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000)),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => store.removeTask(task.id),
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.xmark,
                  color: kTextTertiary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explainer cards ───────────────────────────────────────────────────────────

class _PatternBExplainer extends StatelessWidget {
  const _PatternBExplainer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A84FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pattern B — Store class',
            style: TextStyle(
              color: Color(0xFF0A84FF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'class TaskStore {\n'
            '  final tasks   = signal<List<Task>>([]);\n'
            '  late final doneCount = computed(() => ...);\n'
            '\n'
            '  void addTask(String t)  => tasks.update(...);\n'
            '  void toggleDone(String id) => tasks.update(...);\n'
            '}',
            style: TextStyle(
                color:
                    isDark ? const Color(0xFF30D158) : const Color(0xFF1E8E3E),
                fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'No base class. No registry. Plain Dart.',
            style: TextStyle(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvidedExplainer extends StatelessWidget {
  const _ProvidedExplainer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30D158), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provided<T> — per-subtree DI',
            style: TextStyle(
              color: Color(0xFF30D158),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '// Wrap:\n'
            'Provided<TaskStore>(value: store, child: ...)\n'
            '\n'
            '// Read anywhere below:\n'
            'final store = Provided.of<TaskStore>(context);',
            style: TextStyle(
                color:
                    isDark ? const Color(0xFF30D158) : const Color(0xFF1E8E3E),
                fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Replaces ProviderScope(overrides:) — no Riverpod needed.',
            style: TextStyle(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
