defaultPermutationTable = [
  151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
  140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
  247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
  57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68,
  175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111,
  229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244,
  102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208,
  89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109,
  198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147,
  118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
  189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70,
  221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 9, 98, 108,
  110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251,
  34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235,
  249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204,
  176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114,
  67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
]

gradientVectors = new Int8Array [
   1.0,  1.0,  0.0
  -1.0,  1.0,  0.0
   1.0, -1.0,  0.0
  -1.0, -1.0,  0.0
   1.0,  0.0,  1.0
  -1.0,  0.0,  1.0
   1.0,  0.0, -1.0
  -1.0,  0.0, -1.0
   0.0,  1.0,  1.0
   0.0, -1.0,  1.0
   0.0,  1.0, -1.0
   0.0, -1.0, -1.0
   1.0,  1.0,  0.0
   0.0, -1.0,  1.0
  -1.0,  1.0,  0.0
   0.0, -1.0, -1.0
]

F2 = (0.5 * (Math.sqrt(3.0) - 1.0))
G2 = ((3.0 - Math.sqrt(3.0)) / 6.0)
F3 = (1.0 / 3.0)
G3 = (1.0 / 6.0)


RAND_MAX = Math.pow(2, 32) - 1
fastRandom = (seed) ->
  v = seed
  u = 521288629
  ->
    v = 36969 * (v & 65535) + (v >> 16)
    u = 18000 * (u & 65535) + (u >> 16)
    ((v << 16) + u) / RAND_MAX


randomizeTable = (table, seed) ->
  random = fastRandom seed
  for i in [table.length...1]
    j = parseInt random() * (i + 1)
    [table[i], table[j]] = [table[j], table[i]]


class PerlinGenerator
  constructor: (seed) ->
    @seed = parseInt seed
    @permutationTable = new Uint8Array defaultPermutationTable
    @period = @permutationTable.length
    randomizeTable @permutationTable, @seed

  simpleNoise2D: (x, y) ->
    noise = 0.0
    pt = @permutationTable
    gv = gradientVectors
    p = @period

    s = (x + y) * F2
    i = Math.floor(x + s)
    j = Math.floor(y + s)
    t = (i + j) * G2
    x0 = x - (i - t)
    y0 = y - (j - t)

    if x0 > y0
      i1 = 1; j1 = 0
    else
      i1 = 0; j1 = 1

    x1 = x0 - i1 + G2
    y1 = y0 - j1 + G2
    x2 = x0 + G2 * 2.0 - 1.0
    y2 = y0 + G2 * 2.0 - 1.0
    ii = (i % p + p) % p
    jj = (j % p + p) % p
    gi0 = pt[(ii + pt[jj % p]) % p] % 12
    gi1 = pt[(ii + i1 + pt[(jj + j1) % p]) % p] % 12
    gi2 = pt[(ii + 1 + pt[(jj + 1) % p]) % p] % 12

    tt = 0.5 - x0 * x0 - y0 * y0
    if tt > 0.0
      gv0 = gv[gi0 * 3]
      gv1 = gv[gi0 * 3 + 1]
      noise += tt * tt * tt * tt * (gv0 * x0 + gv1 * y0)
    tt = 0.5 - x1 * x1 - y1 * y1
    if tt > 0.0
      gv0 = gv[gi1 * 3]
      gv1 = gv[gi1 * 3 + 1]
      noise += tt * tt * tt * tt * (gv0 * x1 + gv1 * y1)
    tt = 0.5 - x2 * x2 - y2 * y2
    if tt > 0.0
      gv0 = gv[gi2 * 3]
      gv1 = gv[gi2 * 3 + 1]
      noise += tt * tt * tt * tt * (gv0 * x2 + gv1 * y2)

    noise * 70.0

  simpleNoise3D: (x, y, z) ->
    noise = 0.0

    pt = @permutationTable
    gv = gradientVectors
    p = @period

    s = (x + y + z) * F3
    i = Math.floor x + s
    j = Math.floor y + s
    k = Math.floor z + s
    t = (i + j + k) * G3
    x0 = x - (i - t)
    y0 = y - (j - t)
    z0 = z - (k - t)

    if x0 >= y0
      if y0 >= z0
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0
      else if (x0 >= z0)
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1
      else
        i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1
    else
      if (y0 < z0)
        i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1
      else if (x0 < z0)
        i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1
      else
        i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0

    x1 = x0 - i1 + G3
    y1 = y0 - j1 + G3
    z1 = z0 - k1 + G3
    x2 = x0 - i2 + 2.0 * G3
    y2 = y0 - j2 + 2.0 * G3
    z2 = z0 - k2 + 2.0 * G3
    x3 = x0 - 1.0 + 3.0 * G3
    y3 = y0 - 1.0 + 3.0 * G3
    z3 = z0 - 1.0 + 3.0 * G3
    ii = (i % p + p) % p
    jj = (j % p + p) % p
    kk = (k % p + p) % p

    gi0 = pt[(ii + pt[(jj + pt[kk % p]) % p]) % p] % 12
    gi1 = pt[(ii + i1 + pt[(jj + j1 + pt[(kk + k1) % p]) % p]) % p] % 12
    gi2 = pt[(ii + i2 + pt[(jj + j2 + pt[(kk + k2) % p]) % p]) % p] % 12
    gi3 = pt[(ii + 1 + pt[(jj + 1 + pt[(kk + 1) % p]) % p]) % p] % 12

    tt = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
    if tt > 0.0
      gv0 = gv[gi0 * 3]
      gv1 = gv[gi0 * 3 + 1]
      gv2 = gv[gi0 * 3 + 2]
      noise += tt * tt * tt * tt * (gv0 * x0 + gv1 * y0 + gv2 * z0)
    tt = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
    if tt > 0.0
      gv0 = gv[gi1 * 3]
      gv1 = gv[gi1 * 3 + 1]
      gv2 = gv[gi1 * 3 + 2]
      noise += tt * tt * tt * tt * (gv0 * x1 + gv1 * y1 + gv2 * z1)
    tt = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
    if tt > 0.0
      gv0 = gv[gi2 * 3]
      gv1 = gv[gi2 * 3 + 1]
      gv2 = gv[gi2 * 3 + 2]
      noise += tt * tt * tt * tt * (gv0 * x2 + gv1 * y2 + gv2 * z2)
    tt = 0.6 - x3 * x3 - y3 * y3 - z3 * z3
    if tt > 0.0
      gv0 = gv[gi3 * 3]
      gv1 = gv[gi3 * 3 + 1]
      gv2 = gv[gi3 * 3 + 2]
      noise += tt * tt * tt * tt * (gv0 * x3 + gv1 * y3 + gv2 * z3)

    noise * 32.0

  noise2D: (x, y, octaves = 1) ->
    total = 0.0
    freq = 1.0

    i = 0
    while i < octaves
      total += this.simpleNoise2D(x * freq, y * freq) / freq
      freq *= 2.0
      i++

    total

  noise3D: (x, y, z, octaves = 1) ->
    total = 0.0
    freq = 1.0

    i = 0
    while i < octaves
      total += this.simpleNoise3D(x * freq, y * freq, z * freq) / freq
      freq *= 2.0
      i++

    total


public = self.webglmc ?= {}
public.PerlinGenerator = PerlinGenerator
