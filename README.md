bat-scripts
===========

BAT files that I use in my Windows environments, to make life easier

<hr>
#### <a href="http://www.flaticon.com/authors/dave-gandy">![icon credit: dave-gandy](http://cdn.flaticon.com/png/24/4426.png)</a> [backup_dump.bat : backup a database in a password protected zip file] (https://github.com/paulera/bat-scripts/blob/master/backup_dump.bat)
I made this script as a quick way to get snapshots of my local databases. It uses the mysqldump command to generate a database dump and compress it as a mpassword protected zip file.

Depending on the project size, when commiting code, I commit a database snapshot generated by this script together.

<hr>
####<a href="http://www.flaticon.com/authors/designmodo">![icon credit: designmodo](http://cdn.flaticon.com/png/32/25406.png)</a>[hgchg.bat : list changes in a Mercurial repository] (https://github.com/paulera/bat-scripts/blob/master/hgchg.bat)
Handy script if you work with the Mercurial version control system. You can run `hgchg /help` for usage instructions.

This script need a few additional executable files to work properly: sed.exe, sort.exe, uniq.exe and cut.exe. They can all be found in the [unxutils project](http://sourceforge.net/projects/unxutils/files/unxutils/current/UnxUtils.zip/download) and their location must be added to the __%PATH%__ environment variable in order to work from enywhere.

```
Syntax: hgchg   [/me]
                [/u &lt;username&gt; ...]
                [ [/sd &lt;start date&gt;] [/fd &lt;final date&gt;] | [/rd &lt;-X days&gt;] ]
                [/w &lt;word&gt; ...] [/wo &lt;word&gt; ...]
                [/rev] [/age] [/c]
                [/min] [/tab] [/clip] [/o &lt;outputfile&gt;]
                [/help]
```

**USERS**
<table>
<tr><td width="120"><b>/u</b> username</td><td>Show changes only for specific users./u can be used many times. ex: hgchg/u user1/u user2/u user3</td></tr>
<tr><td><b>/me</b> or <b>/1</b></td><td>Show changes for the current logged user.</td></tr>
</table>

**FILTERS**
<table>
<tr><td><b>/sd</b> &lt;start date&gt;</td><td>Start date in the format YYYY-MM-DD. Current date is the default.</td></tr>
<tr><td><b>/fd</b> &lt;final date&gt;</td><td>Final date in the format YYYY-MM-DD. Current date is the default.</td></tr>
<tr><td><b>/rd</b> &lt;-X&gt;</td><td>Gets data from X days ago until today. Overrides/sd and/fd</td></tr>
<tr><td><b>/date</b> &lt;YYYY-MM-DD&gt;</td><td>Gets data from a specific date. Overrides/sd,/fd and/rd.</td></tr>
<tr><td><b>/w</b> &lt;word&gt;</td><td>Only results WITH the word./w can be used many times.</td></tr>
<tr><td><b>/wo</b> &lt;word&gt;</td><td>Only results WITHOUT the word./wo can be used many times.</td></tr>
</table>

**LIST STYLE**
<table>
<tr><td width="120"><b>/rev or <b>/r</b></td><td>Show revision number</td></tr>
<tr><td><b>/age</b> or <b>/a</b></td><td>Show age, e.g. "10 hours ago", "2 weeks ago"</td></tr>
<tr><td><b>/c</b></td><td>Show commit comments (first line only)</td></tr>
<tr><td><b>/time</b></td><td>Show the time with the date</td></tr>
<tr><td><b>/tab</b> or <b>/t</b></td><td>Tab mode - split columns using tabs, useful with/clip to use on excel</td></tr>
<tr><td><b>/min</b> or <b>/m</b></td><td>Minimal mode (list unique files, sorted). Overrides/r and/a.</td></tr>
<tr><td><b>/clip</b></td><td>Output the results to the clipboard instead of displaying them</td></tr>
<tr><td><b>/o</b> &lt;file&gt;</td><td>Output the results to the specified file. USE DOUBLE QUOTES or ESCAPE BACKSLASH (use c:\\file.txt instead of c:\file.txt)</td></tr>
</table>

**OTHERS**
<table>
<tr><td><b>/help</b> or <b>/?</b></td><td>Display this help (using "/?" doesn't work)</td></tr>
<tr><td><b>/v</b></td><td>Verbose</td></tr>
<tr><td><b>/debug</b></td><td>Show debug messages.</td></tr>
<tr><td><b>/rawdebug</b></td><td>Show debug messages and echoes every line executed in the script (ECHO ON)</td></tr>
<tr><td><b>/check</b></td><td>Check dependencies and show instructions about how to properly install them.</td></tr>
</table>

**SEETTING UP THE PROJECTS LIST**
<table>
<tr><td>Create a file HGCHG.CFG in the same place where the HGCHG.BAT is located, containing a list of the projects' root folders. Use # to comment lines.</td></tr>
</table>

<hr>
####<a href="http://www.flaticon.com/authors/icons8">![icon credit: Icons8](http://cdn.flaticon.com/png/24/48243.png)</a> [pingog.bat : check internet connection] (https://github.com/paulera/bat-scripts/blob/master/pingog.bat)
Ping the address www.google.com to check the internet connection (assuming that Google server never goes down).

