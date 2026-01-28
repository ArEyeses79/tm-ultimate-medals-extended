#if TMNEXT
// based on XertroV's 'metadata gateway' plugin
const uint16 O_MAP_SCRIPTMD = Reflection::GetType("CGameCtnChallenge").GetMember("ScriptMetadata").Offset;
const uint SZ_METADATA_ROW = 0x88;

bool IsClones(CGameCtnChallenge@ rootmap) {
    if (rootmap.ScriptMetadata is null) {
        warn('map has no script metadata');
        return false;
    }
    if (O_MAP_SCRIPTMD == 0xFFFF) {
        warn('script metadata offset is invalid (0xFFFF)');
        return false;
    }
    uint64 scriptMdLoc = Dev::GetOffsetUint64(rootmap, O_MAP_SCRIPTMD);
    uint64 pointer = Dev::ReadUInt64(scriptMdLoc + 0x28);
    uint64 length = Dev::ReadUInt64(scriptMdLoc + 0x30);
    uint32 len;
    string itemName;
    for (uint i = 0; i < length; i++) {
        uint64 itemPointer = pointer + i * SZ_METADATA_ROW;

        if (Dev::ReadUInt32(itemPointer + 0x10) != 1) {
            // not a boolean so skip
            continue;
        }

        len = Dev::ReadUInt32(itemPointer + 0xC);
        if (len == 0) {
            continue;
        }
        itemName = '';
        if (Dev::ReadUInt8(itemPointer + 0xB) & 1 == 1) {
            itemName = Dev::ReadCString(Dev::ReadUInt64(itemPointer), len);
        } else {
            if (len > 11) {
                warn("Reading metadata: string " + i + " is too long for flags! (" + tostring(len) + ")");
                continue;
            }
            itemName = Dev::ReadCString(itemPointer, len);
        }
        if (itemName != 'Nadeo_IsCloneEnabled') {
            continue;
        }
        return Dev::ReadInt32(itemPointer + 0x18) >= 1;
    }
    return false;
}

#endif