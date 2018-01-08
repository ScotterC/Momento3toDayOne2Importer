# Momento 3 to DayOne 2 Importer

# Usage

## Dependencies

- Download [DayOne's CLI](http://help.dayoneapp.com/day-one-2-0/command-line-interface-cli)

- [Export Momento Data](https://momento.zendesk.com/hc/en-us/articles/207965865-Export-FAQ) with a text file for each date
  - This will create a folder with many text files and an Attachments folder within with all media
- Clone or download this repo
- Run by `./momento3todayone2import.rb /path/to/momento/folder`

# Notes

- Treat this as Alpha software. I made it for my own uses and it relies on RegEx than I'd prefer
- This does not import videos because DayOne doesn't support it yet. They'll have to be manually scrubbed from the text files
- Tags are created based on Momento feeds
- People and Events aren't really compatible with Day One so left as content
- Imports to main Journal only. Easy to find in code and switch though.
- Each timestamp from each day is made a separate entry into DayOne

## Basic Architecture

- 3 Models: Entry, ExportedFile, Directory
- Directory contains ExportedFiles. ExportedFile contains many entries.
- Entry model is the most complex to pull out relevant metadata from text