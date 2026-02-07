#if TMNEXT
// based on XertroV's 'metadata gateway' plugin
const uint SZ_METADATA_ROW = 0x88;

bool IsClones(CGameCtnChallenge@ rootmap) {
    try {
        // since I'm using safe dev functions, this will throw an error if the game updates to change the offsets
        return _IsClones(rootmap);
    } catch {
        warn(getExceptionInfo());
        return false;
    }
}
bool _IsClones(CGameCtnChallenge@ rootmap) {
    if (rootmap.ScriptMetadata is null) {
        warn('map has no script metadata');
        return false;
    }
    uint64 pointer = Dev::GetOffsetUint64(rootmap.ScriptMetadata, 0x28);
    uint64 length = Dev::GetOffsetUint32(rootmap.ScriptMetadata, 0x30);
    uint32 len;
    string itemName;
    for (uint i = 0; i < length; i++) {
        uint64 itemPointer = pointer + i * SZ_METADATA_ROW;

        if (Dev::SafeReadUInt32(itemPointer + 0x10) != 1) {
            // not a boolean so skip
            continue;
        }
        // read item name
        len = Dev::SafeReadUInt32(itemPointer + 0xC);
        if (len == 0) {
            continue;
        }
        itemName = '';
        if (Dev::ReadUInt8(itemPointer + 0xB) & 1 == 1) {
            itemName = Dev::SafeReadCString(Dev::SafeReadUInt64(itemPointer), len);
        } else {
            if (len > 11) {
                warn("Reading metadata: string " + i + " is too long for flags! (" + tostring(len) + ")");
                continue;
            }
            itemName = Dev::SafeReadCString(itemPointer, len);
        }
        if (itemName != 'Nadeo_IsCloneEnabled') {
            continue;
        }
        return Dev::SafeReadInt32(itemPointer + 0x18) >= 1;
    }
    return false;
}

#endif