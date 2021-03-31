# Techie Workshop

Test ideas for the technical workshop on April 21st

## Cloud Native Buildpacks Hands-on

These are the documents for the CNB workshop

### Outline

* [Preparation - before the workshop](./PREPARATION.md)
* [Introduction to Cloud Native Buildpacks](./INTRO.md)
* [CNB Workshop overview and content](./WORKSHOP.md)
* [Extras (after completing the workshop)](./EXTRAS.md)

### General Notes

To troubleshoot YAML file issues, run the following in `vi`

```
:set list
:set number
:set nopaste
:set tabstop=2 shiftwidth=2 expandtab
:set nowrap
```

This will help with tab/spaces issues causing missalignement of of YAML statements. Line numbers are often reported in error messages.

One problem I found was that the `set paste` option resets the `set expandtab` option in the `.vimrc` file.

To replace all tabs with spaces (after you set tabstops correctly) use `:retab`

