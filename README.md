# Techie Workshop

Test ideas for the technical workshop on April 21st

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

