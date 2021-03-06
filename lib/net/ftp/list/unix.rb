require 'time'
require 'net/ftp/list/parser'

# Parse Unix like FTP LIST entries.
#
# == MATCHES
#
#   drwxr-xr-x   4 steve    group       4096 Dec 10 20:23 etc
#   -rw-r--r--   1 root     other        531 Jan 29 03:26 README.txt
class Net::FTP::List::Unix < Net::FTP::List::Parser

  # Stolen straight from the ASF's commons Java FTP LIST parser library.
  # http://svn.apache.org/repos/asf/commons/proper/net/trunk/src/java/org/apache/commons/net/ftp/
  REGEXP = %r{
    ([pbcdlfmpSs-])
    (((r|-)(w|-)([xsStTL-]))((r|-)(w|-)([xsStTL-]))((r|-)(w|-)([xsStTL-])))\+?\s+
    (\d+)\s+
    (\S+)\s+
    (?:(\S+(?:\s\S+)*)\s+)?
    (?:\d+,\s+)?
    (\d+)\s+
    ((?:\d+[-/]\d+[-/]\d+)|(?:\S+\s+\S+))\s+
    (\d+(?::\d+)?)\s+
    (\S*)(\s*.*)
  }x

  ONE_YEAR = (60 * 60 * 24 * 365)

  # Parse a Unix like FTP LIST entries.
  def self.parse(raw)
    match = REGEXP.match(raw.strip) or return false

    dir, symlink, file, device = false, false, false, false
    case match[1]
      when /d/      then dir = true
      when /l/      then symlink = true
      when /[f-]/   then file = true
      when /[psbc]/ then device = true
    end
    return false unless dir or symlink or file or device

    # TODO: Permissions, users, groups, date/time.
    filesize = match[18].to_i
    mtime = Time.parse("#{match[19]} #{match[20]}")
    mtime -= ONE_YEAR if mtime > Time.now

    basename = match[21].strip

    # filenames with spaces will end up in the last match
    basename += match[22] unless match[22].nil?

    # strip the symlink stuff we don't care about
    basename.sub!(/\s+\->.+$/, '') if symlink

    emit_entry(
      raw,
      :dir => dir,
      :file => file,
      :device => device,
      :symlink => symlink,
      :filesize => filesize,
      :basename => basename,
      :mtime => mtime
    )
  end
end
