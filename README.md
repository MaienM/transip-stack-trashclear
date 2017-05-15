# TransIP Stack Trashclear

TransIP's Stack file storage service can be used via webdav. However, when you
delete files through webdav, they are moved to trash, with no way for you to
actually delete them. Over time, this will eat up your space.

This is a script that clears your trashbin, fixing this problem.

## Usage

You'll need ruby, because that's what this is written in.

Copy `example_env` to some filename, and fill in the info.

```
bundle install
ruby trashclear.rb path_to_env_file
```
