import os, streams
export streams

when defined(windows):
  const libbz2 = "bzip2.dll"
elif defined(macosx):
  const libbz2 = "libbz2.dylib"
else:
  const libbz2 = "libbz2.so"

type
  BzFile* = ptr object

proc bzlibVersion*(): cstring {.cdecl, dynlib: libbz2,
  importc: "BZ2_bzlibVersion".}

proc bzopen*(path: cstring, mode: cstring): BzFile {.cdecl, dynlib: libbz2,
  importc: "BZ2_bzopen".}

proc bzread*(thefile: BzFile, buf: pointer, length: int): int32 {.cdecl,
  dynlib: libbz2, importc: "BZ2_bzread".}

proc bzwrite*(thefile: BzFile, buf: pointer, length: int): int32 {.cdecl,
  dynlib: libbz2, importc: "BZ2_bzwrite".}

proc bzclose*(thefile: BzFile): int32 {.cdecl, dynlib: libbz2,
  importc: "BZ2_bzclose".}

proc bzerror*(thefile: BzFile, errnum: var int32): cstring {.cdecl,
  dynlib: libbz2, importc: "BZ2_bzerror".}

# Streams
type
  BzFileStream* = ref object of Stream
    f: BzFile

proc fsClose(s: Stream) =
  let s = BzFileStream(s)
  if not s.f.isNil:
    discard bzclose(s.f)
    s.f = nil

proc fsReadData(s: Stream, buffer: pointer, bufLen: int): int =
  result = bzread(BzFileStream(s).f, buffer, bufLen).int
  if result == -1:
    raise newException(IOError, "cannot read from stream!")

proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) =
  let res = bzwrite(BzFileStream(s).f, buffer, bufLen).int
  if res != bufLen:
    raise newException(IOError, "cannot write to stream!")

proc newBzFileStream*(filename: string, mode=fmRead): BzFileStream =
  ## Opens a BzFile as a file stream. `mode` can only be ``fmRead`` or ``fmWrite``.
  new(result)
  case mode
  of fmRead:
    result.f = bzopen(filename, "rb")
    result.readDataImpl = fsReadData
  of fmWrite:
    result.f = bzopen(filename, "wb")
    result.writeDataImpl = fsWriteData
  else: raise newException(IOError, "unsupported file mode '" & $mode &
                          "' for BzFileStream!")
  if result.f.isNil:
    let err = osLastError()
    if err != OSErrorCode(0'i32):
      raiseOSError(err)

  result.closeImpl = fsClose
