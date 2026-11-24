/// Most people in a challenge group, counting pending invites.
const kMaxChallengeGroupMembers = 20;

/// Longest group name, after trimming.
const kMaxChallengeGroupNameLength = 40;

/// Longest group description, after trimming. The description is optional.
const kMaxChallengeGroupDescriptionLength = 200;

/// Public groups listed in "Find a group" (newest first) and the most
/// search results returned.
const kPublicGroupsLimit = 30;

/// Most people returned by people search.
const kPeopleSearchLimit = 20;

/// Length of a group's join code (also its document id).
const kChallengeGroupCodeLength = 6;

/// Characters of a join code: upper-case letters and digits without the
/// look-alikes 0/O and 1/I.
const kChallengeGroupCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
