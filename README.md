# TransIP Stack Trashclear

TransIP's Stack file storage service can be used via webdav. However, when you
delete files through webdav, they are moved to trash, with no way for you to
actually delete them. Over time, this will eat up your space.

This is a script that clears your trashbin, fixing this problem.

## Usage

Copy `example_env` to some filename, and fill in the info. Alternatively, set
the environment variables in another manner.

## The easy way

```
docker run --rm --env-file=path_to_env_file maienm/transip-stack-trashclear
```

### The hard way

You'll need ruby, because that's what this is written in.

```
bundle install
ruby trashclear.rb path_to_env_file
```
