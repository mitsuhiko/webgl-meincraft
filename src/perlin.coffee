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

gradientVectors = [
  [ 1.0,  1.0,  0.0]
  [-1.0,  1.0,  0.0]
  [ 1.0, -1.0,  0.0]
  [-1.0, -1.0,  0.0]
  [ 1.0,  0.0,  1.0]
  [-1.0,  0.0,  1.0]
  [ 1.0,  0.0, -1.0]
  [-1.0,  0.0, -1.0]
  [ 0.0,  1.0,  1.0]
  [ 0.0, -1.0,  1.0]
  [ 0.0,  1.0, -1.0]
  [ 0.0, -1.0, -1.0]
  [ 1.0,  1.0,  0.0]
  [ 0.0, -1.0,  1.0]
  [-1.0,  1.0,  0.0]
  [ 0.0, -1.0, -1.0]
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

mod = (x, y) ->
  (x % y + y) % y


randomizeTable = (table, seed) ->
  random = fastRandom seed
  for i in [table.length...1]
    j = parseInt random() * (i + 1)
    [table[i], table[j]] = [table[j], table[i]]


class PerlinGenerator
  constructor: (seed) ->
    @seed = parseInt seed
    @permutationTable = Array::concat defaultPermutationTable
    @period = @permutationTable.length
    randomizeTable @permutationTable, @seed

  simpleNoise2D: (x, y) ->
    noise = 0.0

    pt = (i) => @permutationTable[i % @period]
    admix = (x, y, g) ->
      tt = 0.5 - Math.pow(x, 2.0) - Math.pow(y, 2.0)
      if tt > 0.0 && !isNaN g
        gvec = gradientVectors[g]
        noise += Math.pow(tt, 4.0) * (gvec[0] * x + gvec[1] * y)

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
    ii = mod i, @period
    jj = mod j, @period
    gi0 = mod pt(ii + pt(jj)), 12
    gi1 = mod pt(ii + i1 + pt(jj + j1)), 12
    gi2 = mod pt(ii + 1 + pt(jj + 1)), 12

    admix x0, y0, gi0
    admix x1, y1, gi1
    admix x2, y2, gi2

    noise * 70.0

  noise2D: (x, y, octaves = 1) ->
    total = 0.0
    freq = 1.0

    for i in [0...octaves]
      total += this.simpleNoise2D(x * freq, y * freq) / freq
      freq *= 2.0

    total


public = this.webglmc ?= {}
public.PerlinGenerator = PerlinGenerator
