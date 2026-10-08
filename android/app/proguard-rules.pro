# Room 2.2.5 creates generated databases with Class.forName(...).newInstance().
# Its class-only consumer rule does not retain constructors in R8 full mode.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkManager 2.7.0 also reflectively creates InputMergers. Its consumer rule
# retains their names but loses their no-argument constructors in full mode.
-keep class * extends androidx.work.InputMerger {
    <init>();
}
