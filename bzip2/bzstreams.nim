import os, streams
import ../bzip2
export streams

## This module implements a bzip2file stream for reading.

type
  Bz2FileStream* = ref object of Stream
    f: Bz2File

proc fsClose(s: Stream) =
  let s = Bz2FileStream(s)
  if not s.f.isNil:
    discard bz2close(s.f)
    s.f = nil

proc fsReadData(s: Stream, buffer: pointer, bufLen: int): int =
  result = bz2read(Bz2FileStream(s).f, buffer, bufLen).int
  if result == -1:
    raise newException(IOError, "cannot read from stream!")

proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) =
  let res = bz2write(Bz2FileStream(s).f, buffer, bufLen).int
  if res != bufLen:
    raise newException(IOError, "cannot write to stream!")

proc newBz2FileStream*(filename: string, mode=fmRead): Bz2FileStream =
  ## Opens a Bz2file as a file stream. `mode` can only be ``fmRead`` or ``fmWrite``.
  new(result)
  case mode
  of fmRead:
    result.f = bz2open(filename, "rb")
    result.readDataImpl = fsReadData
  of fmWrite:
    result.f = bz2open(filename, "wb")
    result.writeDataImpl = fsWriteData
  else: raise newException(IOError, "unsupported file mode '" & $mode &
                          "' for Bz2FileStream!")
  if result.f.isNil:
    let err = osLastError()
    if err != OSErrorCode(0'i32):
      raiseOSError(err)

  result.closeImpl = fsClose
