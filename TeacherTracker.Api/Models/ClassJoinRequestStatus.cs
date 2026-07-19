namespace TeacherTracker.Api.Models;

/// The state of a <see cref="ClassJoinRequest"/> in the Waiting Lobby. Stored as
/// text (see AppDbContext).
public enum ClassJoinRequestStatus
{
    /// Submitted by the student; awaiting the teacher's decision. The student has
    /// no access to the class in this state.
    Pending,

    /// The teacher accepted; an <see cref="Enrollment"/> now exists and the
    /// student is a full member.
    Approved,

    /// The teacher declined. Kept as a record (anti-abuse / history); the student
    /// may submit a fresh request later.
    Rejected,
}
