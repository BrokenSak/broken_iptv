import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/epg_program.dart';
import '../../../state/live_providers.dart';
import '../../common/tv_focusable.dart';

class EpgScreen extends ConsumerWidget {
  const EpgScreen({super.key, required this.streamId, required this.channelName});

  final String streamId;
  final String channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epg = ref.watch(shortEpgProvider(streamId));

    return Scaffold(
      appBar: AppBar(title: Text(channelName.isEmpty ? 'Guida programmi' : channelName)),
      body: epg.when(
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('Nessun dato EPG disponibile per questo canale.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: programs.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) => _ProgramTile(
              program: programs[index],
              streamId: streamId,
              autofocus: index == 0,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
      ),
    );
  }
}

class _ProgramTile extends ConsumerWidget {
  const _ProgramTile({required this.program, required this.streamId, this.autofocus = false});

  final EpgProgram program;
  final String streamId;
  final bool autofocus;

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWatch = program.isPast || program.isLive;

    return TvFocusable(
      autofocus: autofocus,
      onTap: canWatch
          ? () {
              final repo = ref.read(liveRepositoryProvider).value;
              if (repo == null) return;
              final url = program.isLive
                  ? repo.streamUrl(streamId)
                  : repo.timeshiftUrl(streamId, program.start, program.end.difference(program.start));
              context.push(
                Uri(path: '/player', queryParameters: {
                  'url': url,
                  'streamId': streamId,
                }).toString(),
              );
            }
          : () {},
      child: ListTile(
        title: Text(program.title),
        subtitle: Text(
          '${_fmt(program.start)} - ${_fmt(program.end)}'
          '${program.description.isNotEmpty ? '\n${program.description}' : ''}',
        ),
        isThreeLine: program.description.isNotEmpty,
        trailing: program.isLive
            ? const Chip(
                label: Text('In onda', style: TextStyle(color: Colors.black)),
                backgroundColor: Colors.white,
              )
            : (program.isPast
                ? const Icon(Icons.replay, color: AppColors.accent)
                : null),
      ),
    );
  }
}
