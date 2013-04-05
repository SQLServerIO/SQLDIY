drop table DBProperties
create table DBProperties
(
	DBName varchar(255) null,
	CreateDate datetime null,
	DBVersion  varchar(6) null,
	Collation varchar(255) null,
	CompatibilityLevel varchar(255) null,
	RecoveryModel varchar(20) null,
	PageVerify varchar(20) null,
	CurrentStatus varchar(20) null,
	AutoCreateStatisticsEnabled varchar(6) null,
	AutoUpdateStatisticsEnabled varchar(6) null,
	AutoShrink varchar(6) null,
	IsDatabaseSnapshot varchar(6) null,
	IsParameterizationForced varchar(6) null,
	IsReadCommittedSnapshotOn varchar(6) null,
	IsMirroringEnabled varchar(6) null,
	BrokerEnabled varchar(6) null,
	ChangeTrackingEnabled varchar(6) null,
	IsFullTextEnabled varchar(6) null
)
