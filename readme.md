# Webpm

Web projects manager (Webpm) is a bash script designed to make my work easier.

Webpm builds a web project to the `web_env_dir` (by default `/var/www/html`) copying all files and directories. When requested, it finishes a built project saving the modified files and deleting the built project folder in `web_env_dir`.

## Usage

### Executing

```
$ ./webpm.sh

or

$ bash webpm.sh
```

**Recomendation:** Create an alias to Webpm in `~/.bashrc` file. Example:

```bash
# .bashrc file

# ...

alias webpm='[path]/webpm.sh'
```

With alias, you can use Webpm easier without mention your path:

```
$ webpm show
```

### Build project

```
$ webpm build <name> [project dir]
```

Build the project passed in `[project dir>]` in the current web_env_dir setting `<name>` as build name. Webpm will build current directory if `[project dir]` isn't provided. 


### Finish project

```
$ webpm finish <build name> [save dir]
```

Finish built project with name `<build name>` and save it in the `[save dir]`. If `[save dir]` is empty, Webpm will save it in the dir where it was built. 

### See current built projects

```
$ webpm show
```

### Set other web_env_dir

```
$ webpm web-environment <new dir>

or 

$ webpm we <new dir>
```
