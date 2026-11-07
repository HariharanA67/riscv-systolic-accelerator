import struct
data = open('/tmp/opt.bin', 'rb').read()
print('binary bytes:', len(data))
data += b'\0' * ((-len(data)) % 4)
words = [struct.unpack('<I', data[i:i+4])[0] for i in range(0, len(data), 4)]
with open('sim/prog_opt.hex', 'w') as f:
    f.write('@0\n')
    for w in words:
        f.write(f'{w:08x}\n')
print('wrote sim/prog_opt.hex:', len(words), 'words')
