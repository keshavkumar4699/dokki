/// Identifier aliases.
///
/// All IDs are UUID text (UUIDv7 for entities, UUIDv4 for blobs). They are
/// distinct *names* in the type system purely for readability; nominal
/// wrappers would add friction across the Drift boundary without safety
/// benefit, since every ID is an opaque string the domain never parses.
library;

typedef EntryId = String;
typedef AssetId = String;
typedef VersionId = String;
typedef BlobId = String;
typedef DeviceId = String;
typedef ExportId = String;
typedef ConflictId = String;
typedef SyncOpId = int;
