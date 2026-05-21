# AUv3 Host Validation Guide

Use this guide for the first real iPad tests in AUM or Loopy Pro.

## Goal

Confirm that NestChord can load as an AUv3 MIDI plugin, follow host transport, emit MIDI chords, save/restore state, and avoid stuck notes during common host actions.

## Recommended First Setup

1. Install the NestChord app on the iPad.
2. Open AUM or Loopy Pro.
3. Add NestChord as an AUv3 MIDI plugin:
   - Name: `NestChord`
   - Type/tag: MIDI or sequencer
4. Add an AUv3 instrument or external MIDI destination.
5. Route NestChord MIDI output into that instrument.
6. Press host play.

NestChord does not generate audio. If there is no synth or external instrument receiving MIDI, it will be silent even when MIDI output is working.

## Expected Results

- The plugin UI opens without showing local debug transport controls.
- The Debug I/O panel shows a Host Sync strip.
- Host Sync shows tempo, beat, meter, playing/stopped state, frame count, sample rate, MIDI event count, and jump/discontinuity state.
- Editing Chord Blocks in the UI changes the chord progression heard from the synth.
- Changing a block's MIDI channel routes emitted notes to that channel.
- Host stop flushes active notes.
- Host jumps or loop wraps do not leave stuck notes.
- Host session save/reopen restores the edited progression.

## Test Script

1. Load the default 4-bar seed.
2. Route NestChord to a synth listening on MIDI channel 1.
3. Press play in the host.
4. Confirm the Host Sync strip changes from `Stopped` to `Playing`.
5. Confirm beat position advances.
6. Confirm MIDI event count becomes non-zero on chord boundaries.
7. Change the first block's degree.
8. Confirm playback follows the edited degree.
9. Change the first block's MIDI channel to 2.
10. Route the synth to channel 2 or add a second synth on channel 2.
11. Confirm notes follow the changed channel.
12. Stop the host and listen for stuck notes.
13. Jump the host transport or restart playback mid-loop.
14. Save the host session, close it, reopen it, and confirm the progression restores.

## Troubleshooting

### Plugin Not Visible

- Confirm the containing NestChord app is installed on the iPad.
- Restart the host after installing a new build.
- Check the MIDI/sequencer AUv3 category, not only audio instruments or effects.
- If the host caches AUv3 lists, rescan plugins or reboot the iPad.

### No MIDI

- Confirm the host transport is playing.
- Confirm the Host Sync strip shows `Playing`.
- Confirm the Host Sync MIDI count becomes non-zero at chord boundaries.
- Confirm the current block is not a rest.
- Confirm the block velocity is above zero.
- Confirm the MIDI channel matches the receiving instrument.

### No Sound

- NestChord does not generate audio.
- Add a synth, sampler, hardware destination, or AUv3 instrument.
- Route NestChord MIDI output into that sound source.
- Confirm the sound source is monitoring the same MIDI channel as the Chord Block.

### Transport Not Moving

- Some hosts do not send musical context until playback starts.
- Press play in the host rather than the NestChord UI.
- Check whether the Host Sync beat value advances.
- If tempo or beat remain at fallback values, record the host name and exact routing setup.

### Stuck Notes

- Stop the host and confirm notes release.
- Try a transport jump and confirm old notes release before new chord notes begin.
- Delete or edit the active block and confirm old notes release on the next render.
- If a note remains stuck, capture the host, tempo, block layout, channel, and last visible Host Sync values.

## Known Limitations

- MIDI note-on and note-off only.
- No MIDI CC output yet.
- No program change.
- No MIDI input processing.
- No AU parameter automation.
- The render path still needs a release-grade real-time-safety audit after host behavior is validated.
