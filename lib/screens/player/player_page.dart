import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:songify/screens/player/widgets/play_pause_buton.dart';
import 'package:songify/utils/song_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yt_music/ytmusic.dart';

import '../../generated/l10n.dart';
import '../../services/download_manager.dart';
import '../../services/media_player.dart';
import '../../themes/colors.dart';
import '../../themes/dark.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import 'widgets/lyrics_box.dart';
import 'widgets/queue_list.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, this.videoId});
  final String? videoId;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late PanelController panelController;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  Color? color;
  ImageProvider? backgroundImage;
  bool canPop = false;
  bool showLyrics = false;
  bool fetchedSong = false;
  late MediaItem? currentSong;

  @override
  void initState() {
    super.initState();
    panelController = PanelController();
    if (widget.videoId != null) {
      GetIt.I<YTMusic>().getSongDetails(widget.videoId!).then((song) {
        if (song != null) {
          GetIt.I<MediaPlayer>().playSong(song);
          setState(() {
            fetchedSong = true;
          });
        }
      });
    }
    currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
    GetIt.I<MediaPlayer>().currentSongNotifier.addListener(songListener);
  }

  @override
  dispose() {
    GetIt.I<MediaPlayer>().currentSongNotifier.removeListener(songListener);
    super.dispose();
  }

  void songListener() {
    if (currentSong != GetIt.I<MediaPlayer>().currentSongNotifier.value) {
      if (mounted) {
        setState(() {
          currentSong = GetIt.I<MediaPlayer>().currentSongNotifier.value;
        });
      }
    }
  }

  void setShowLyrics() {
    if (mounted) {
      setState(() {
        showLyrics = !showLyrics;
      });
    }
  }

  Future<void> updateBackgroundColor(ImageProvider image) async {
    if (mounted) {
      setState(() {
        backgroundImage = image;
      });
    }
    final c = await ColorScheme.fromImageProvider(provider: image);
    if (mounted) {
      setState(() {
        color = c.primary;
      });
    }
  }

  MaterialColor primaryWhite = const MaterialColor(0xFFFFFFFF, <int, Color>{
    50: Color(0xFFFFFFFF),
    100: Color(0xFFFFFFFF),
    200: Color(0xFFFFFFFF),
    300: Color(0xFFFFFFFF),
    400: Color(0xFFFFFFFF),
    500: Color(0xFFFFFFFF),
    600: Color(0xFFFFFFFF),
    700: Color(0xFFFFFFFF),
    800: Color(0xFFFFFFFF),
    900: Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryWhite,
          primary: primaryWhite,
          brightness: Brightness.dark,
        ),
      ),
      child: (widget.videoId != null && fetchedSong == false)
          ? const Center(child: AdaptiveProgressRing())
          // ignore: deprecated_member_use
          : WillPopScope(
              onWillPop: () async {
                if (panelController.isAttached && panelController.isPanelOpen) {
                  await panelController.close();
                  return false;
                }
                return true;
              },
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarBrightness: Brightness.dark,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                ),
                child: Stack(
                  children: [
                    if (backgroundImage != null)
                      Positioned.fill(
                        child: Image(
                          image: backgroundImage!,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          gaplessPlayback: true,
                        ),
                      ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (color ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow)
                                .withOpacity(0.4),
                            (color ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow)
                                .withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Scaffold(
                      appBar: PreferredSize(
                        preferredSize: const Size.fromHeight(80),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 16, left: 24, right: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.expand_more, color: Colors.white),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'NOW PLAYING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentSong?.title ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${currentSong?.artist ?? ''} • ${currentSong?.album ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                                  onPressed: () {
                                      Modals.showPlayerOptionsModal(
                                        context,
                                        GetIt.I<MediaPlayer>().currentSongNotifier.value!.extras!,
                                      );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      key: _key,
                      backgroundColor: Colors.transparent,
                      endDrawer:
                          MediaQuery.of(context).size.width >
                                  MediaQuery.of(context).size.height ||
                              Platform.isWindows
                          ? SizedBox(
                              width:
                                  min(400, MediaQuery.of(context).size.width) -
                                  50,
                              child: const QueueList(),
                            )
                          : null,
                      body: SizedBox(
                        width: double.maxFinite,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            EdgeInsets padding = MediaQuery.of(context).padding;
                            double maxWidth =
                                constraints.maxWidth -
                                padding.left -
                                padding.right;
                            double maxHeight =
                                constraints.maxHeight -
                                padding.top -
                                padding.bottom;
                            if (maxWidth > maxHeight) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Artwork(
                                    setShowLyrics: setShowLyrics,
                                    showLyrics: showLyrics,
                                    width: maxWidth / 2.3,
                                    song: currentSong,
                                    onImageReady: updateBackgroundColor,
                                  ),
                                  NameAndControls(
                                    song: currentSong,
                                    width: maxWidth - (maxWidth / 2.3),
                                    height: maxHeight,
                                    isRow: true,
                                    showLyrics: showLyrics,
                                    setShowLyrics: setShowLyrics,
                                  ),
                                ],
                              );
                            }
                            return Stack(
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Artwork(
                                      setShowLyrics: setShowLyrics,
                                      showLyrics: showLyrics,
                                      width:
                                          min(maxWidth, maxHeight / 2.2) - 24,
                                      song: currentSong,
                                      onImageReady: updateBackgroundColor,
                                    ),
                                    NameAndControls(
                                      song: currentSong,
                                      width: maxWidth,
                                      height:
                                          maxHeight -
                                          min(maxWidth, maxHeight / 2.2) -
                                          24,
                                      showLyrics: showLyrics,
                                      setShowLyrics: setShowLyrics,
                                    ),
                                  ],
                                ),
                                SlidingUpPanel(
                                  controller: panelController,
                                  color: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  margin: EdgeInsets.zero,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  boxShadow: const [],
                                  minHeight:
                                      50 +
                                      MediaQuery.of(context).padding.bottom,
                                  panel: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: Container(
                                      width: constraints.maxWidth,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          ClipRRect(
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 3,
                                                sigmaY: 3,
                                              ),
                                              child: Container(
                                                height:
                                                    50 +
                                                    MediaQuery.of(
                                                      context,
                                                    ).padding.bottom,
                                                width: double.maxFinite,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor
                                                      .withAlpha(70),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                      ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      height: 5,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        color: greyColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      S.of(context).Next_Up,
                                                      style: textStyle(
                                                        context,
                                                        bold: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: QueueList()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class Artwork extends StatelessWidget {
  const Artwork({
    this.song,
    required this.width,
    required this.showLyrics,
    required this.setShowLyrics,
    this.onImageReady,
    super.key,
  });
  final double width;
  final MediaItem? song;
  final bool showLyrics;
  final Function setShowLyrics;
  final void Function(ImageProvider)? onImageReady;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: song == null
            ? Icon(Icons.music_note, size: width * 0.5)
            : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTap: () {
                        setShowLyrics();
                      },
                      child: Center(
                        child: showLyrics
                            ? LyricsBox(
                                currentSong: song!,
                                size: Size(width, width),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(30),
                                      spreadRadius: 10,
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SongThumbnail(
                                    song: song!.extras!,
                                    onImageReady: onImageReady,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class NameAndControls extends StatelessWidget {
  const NameAndControls({
    this.song,
    required this.height,
    required this.width,
    this.isRow = false,
    required this.showLyrics,
    required this.setShowLyrics,
    super.key,
  });
  final double width;
  final double height;
  final MediaItem? song;
  final bool isRow;
  final bool showLyrics;
  final Function setShowLyrics;

  @override
  Widget build(BuildContext context) {
    MediaPlayer mediaPlayer = context.watch<MediaPlayer>();
    return SizedBox(
      height: height,
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextScroll(
                  song?.title ?? 'Title',
                  style: bigTextStyle(context, bold: true),
                  mode: TextScrollMode.endless,
                ),
                Text(
                  song?.artist ??
                      song?.album ??
                      song?.extras?['subtitle'] ??
                      '',
                  style: smallTextStyle(context),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: mediaPlayer.progressBarState,
                  builder: (context, ProgressBarState value, child) {
                    return ProgressBar(
                      progress: value.current,
                      total: value.total,
                      buffered: value.buffered,
                      barHeight: 4,
                      thumbRadius: 6,
                      thumbColor: Colors.white,
                      baseBarColor: Colors.white.withOpacity(0.2),
                      progressBarColor: const Color(0xFF4725f4),
                      bufferedBarColor: Colors.white.withOpacity(0.2),
                      onSeek: (value) => mediaPlayer.player.seek(value),
                      timeLabelTextStyle: const TextStyle(
                         color: Colors.white54,
                         fontSize: 10,
                         fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<bool>(
                      stream: mediaPlayer.player.shuffleModeEnabledStream,
                      builder: (context, snapshot) {
                        final shuffleEnabled = snapshot.data ?? false;
                        return AdaptiveIconButton(
                          onPressed: () {
                            mediaPlayer.player.setShuffleModeEnabled(!shuffleEnabled);
                          },
                          icon: Icon(
                            Icons.shuffle,
                            size: 24,
                            color: shuffleEnabled
                                ? const Color(0xFF4725f4)
                                : Colors.white.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                    AdaptiveIconButton(
                      onPressed: () {
                        mediaPlayer.player.seekToPrevious();
                      },
                      icon: const Icon(Icons.skip_previous, size: 32, color: Colors.white),
                    ),
                    const PlayPauseButton(size: 64),
                    AdaptiveIconButton(
                      onPressed: () {
                        mediaPlayer.player.seekToNext();
                      },
                      icon: const Icon(Icons.skip_next, size: 32, color: Colors.white),
                    ),
                    ValueListenableBuilder(
                      valueListenable: mediaPlayer.loopMode,
                      builder: (context, value, child) {
                        return AdaptiveIconButton(
                          onPressed: () {
                            mediaPlayer.changeLoopMode();
                          },
                          isSelected: value != LoopMode.off,
                          icon: Icon(
                            value == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            size: 24,
                            color: value == LoopMode.off
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF4725f4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.lyrics, color: showLyrics ? const Color(0xFF4725f4) : Colors.white.withOpacity(0.4)),
                      onPressed: () {
                        setShowLyrics();
                      },
                    ),
                  ],
                ),
                Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: Icon(Icons.mic, color: Colors.white.withOpacity(0.4)),
                       onPressed: () {
                         // Feature not implemented
                       },
                     ),
                   ],
                ),
                Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: Icon(Icons.playlist_play, color: Colors.white.withOpacity(0.4)),
                       onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                       },
                     ),
                   ],
                ),
                Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: Icon(Icons.share, color: Colors.white.withOpacity(0.4)),
                       onPressed: () {
                         if (song != null) {
                           Share.share('Check out ${song?.title} by ${song?.artist} on Songify!');
                         }
                       },
                     ),
                   ],
                ),
              ],
            ),
            ),
            if (song != null && !isRow)
              SizedBox(height: 55 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
