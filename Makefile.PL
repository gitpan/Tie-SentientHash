use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Tie::SentientHash',
    'VERSION_FROM' => 'lib/Tie/SentientHash.pm', # finds $VERSION
    'dist'           => { 
	'COMPRESS'   => 'gzip', 
	'SUFFIX'     => 'gz' 
    },
);
