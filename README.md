# overdrive-m4b

A dirty script to convert Overdrive audiobooks to a single m4b file. Use at your own peril.

## Install

```
brew tap pflouret/tap
brew install overdrive-m4b
```

or, if you want to use the official `ffmpeg` without libfdk_aac codec

```
brew tap pflouret/tap
brew install overdrive-m4b --without-fdk-aac
```

## Useful utilites to use in conjunction

- https://github.com/chbrown/overdrive Bash script to download overdrive books.
- https://bendodson.com/projects/itunes-artwork-finder Better artwork than the one supplied by overdrive. Put the downloaded 600x600bb.jpg in the same folder as the mp3s.

## Usage

By default, all actions will be run (merge, add metadata tags, add chapters, add cover).
Specifying one or more specific action, will only run those.

Author and title will be pulled out of the mp3 tags if available. Override with options.

An `<author> - <title>.m4b` file will be left in the directory the command is run.

```
> overdrive-m4b --help
overdrive-m4b [options] <mp3-files>
    -g, --genre=GENRE
    -t, --title=TITLE
    -a, --author=AUTHOR
    -c, --codec=aac|libfdk_aac
    -v, --version
        --merge
        --tags
        --chapters
        --cover
```

```
overdrive-m4b --genre "Non Fiction" Some\ Audiobook/*.mp3
```

## License

Copyright © 2019 Pablo Flouret. [Apache 2.0](https://github.com/pflouret/overdrive-m4b/blob/master/LICENSE)
