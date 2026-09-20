import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/fcbaz_api.dart';
import '../notifications/fcm_push_service.dart';
import 'auth_repository.dart';
import 'backup_repository.dart';
import 'cloud_sync_repository.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final authRepository = AuthRepository();
  final syncRepository = CloudSyncRepository();
  final backupRepository = BackupRepository();
  final pushService = FcmPushService();

  AccountSession? session;
  bool loading = true;
  bool working = false;
  String? status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await authRepository.currentSession();
    if (!mounted) return;
    setState(() {
      session = current;
      loading = false;
    });
  }

  Future<void> _auth({required bool register}) async {
    final email = TextEditingController();
    final password = TextEditingController();

    final credentials = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(register ? 'ساخت حساب FCBaz' : 'ورود به حساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'حداقل ۸ کاراکتر',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (email.text.trim(), password.text),
            ),
            child: Text(register ? 'ثبت‌نام' : 'ورود'),
          ),
        ],
      ),
    );

    email.dispose();
    password.dispose();
    if (credentials == null) return;

    setState(() {
      working = true;
      status = null;
    });

    try {
      final result = register
          ? await authRepository.signUp(
              email: credentials.$1,
              password: credentials.$2,
            )
          : await authRepository.signIn(
              email: credentials.$1,
              password: credentials.$2,
            );

      if (!mounted) return;

      if (result.accessToken.isEmpty) {
        setState(() {
          status =
              'ثبت‌نام انجام شد. اگر Email Confirmation فعال است، ایمیل را تأیید کن و سپس وارد شو.';
        });
      } else {
        session = result;
        final push = await pushService.registerCurrentDevice();
        setState(() {
          status = push.tokenRegistered
              ? 'ورود انجام شد و Push این دستگاه فعال شد.'
              : 'ورود انجام شد؛ Push هنوز تنظیم/ثبت نشده است.';
        });
      }
    } on FCBazApiException catch (e) {
      if (mounted) setState(() => status = e.message);
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _signOut() async {
    await authRepository.signOut();
    if (!mounted) return;
    setState(() {
      session = null;
      status = 'از حساب خارج شدی.';
    });
  }

  Future<void> _upload() async {
    setState(() {
      working = true;
      status = null;
    });
    try {
      final result = await syncRepository.upload();
      if (!mounted) return;
      setState(() {
        status = 'Cloud Backup ذخیره شد • ' +
            result.itemCount.toString() +
            ' بخش';
      });
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _download() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore از Cloud'),
        content: const Text(
          'اطلاعات محلی FCBaz با آخرین Cloud Backup جایگزین شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      working = true;
      status = null;
    });
    try {
      final result = await syncRepository.download();
      if (!mounted) return;
      setState(() {
        status = result.itemCount.toString() +
            ' بخش از Cloud بازیابی شد. برای اعمال کامل تنظیمات، برنامه را دوباره باز کن.';
      });
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _copyBackup() async {
    final raw = await backupRepository.exportJson();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    setState(() => status = 'Backup JSON در Clipboard کپی شد.');
  }

  Future<void> _restoreClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim() ?? '';
    if (raw.isEmpty) {
      setState(() => status = 'Clipboard خالی است.');
      return;
    }

    try {
      final count = await backupRepository.restoreJson(raw);
      if (!mounted) return;
      setState(() {
        status = count.toString() +
            ' بخش بازیابی شد. برای اعمال کامل تنظیمات، برنامه را دوباره باز کن.';
      });
    } catch (e) {
      if (mounted) setState(() => status = 'Restore ناموفق: ' + e.toString());
    }
  }

  Future<void> _registerPush() async {
    setState(() {
      working = true;
      status = null;
    });
    try {
      final result = await pushService.registerCurrentDevice();
      if (!mounted) return;
      setState(() {
        if (!result.configured) {
          status = 'Firebase برای این Build تنظیم نشده است.';
        } else if (!result.permissionGranted) {
          status = 'مجوز اعلان داده نشده است.';
        } else if (!result.tokenRegistered) {
          status = 'Push آماده است ولی برای ثبت Device باید وارد حساب باشی.';
        } else {
          status = 'FCM Push این دستگاه ثبت شد.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حساب و Cloud')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: session == null
                  ? Column(
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'حساب آنلاین متصل نیست',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'برای Cloud Sync و Push بین دستگاه‌ها وارد حساب شو.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: working
                                    ? null
                                    : () => _auth(register: false),
                                child: const Text('ورود'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: working
                                    ? null
                                    : () => _auth(register: true),
                                child: const Text('ثبت‌نام'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(
                                session!.email.isEmpty
                                    ? 'F'
                                    : session!.email.characters.first
                                        .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session!.email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Cloud Account',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: working ? null : _signOut,
                              child: const Text('خروج'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          if (working) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (status != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(status!),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Cloud Sync',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: session == null || working ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Backup به Cloud'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: session == null || working ? null : _download,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Restore از Cloud'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Backup محلی',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyBackup,
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copy Backup'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restoreClipboard,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restore Clipboard'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Push Notification',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text('Firebase Cloud Messaging'),
              subtitle: const Text(
                'بعد از تنظیم Firebase و ورود به حساب، Device Token واقعی روی Backend ثبت می‌شود.',
              ),
              trailing: FilledButton(
                onPressed: working ? null : _registerPush,
                child: const Text('فعال‌سازی'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
