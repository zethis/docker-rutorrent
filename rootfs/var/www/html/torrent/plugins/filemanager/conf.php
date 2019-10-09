<?php

$fm['tempdir'] = '/tmp';                // path were to store temporary data ; must be writable
$fm['mkdperm'] = 755;           // default permission to set to new created directories

$pathToExternals['zip'] = '/usr/bin/zip';
$pathToExternals['unzip'] = '/usr/bin/unzip';
$pathToExternals['tar'] = '/bin/tar';
$pathToExternals['gzip'] = '/bin/gzip';
$pathToExternals['bzip2'] = '/usr/bin/bzip2';

$fm['archive']['types'] = array('zip', 'tar', 'gzip', 'bzip2');
$fm['archive']['compress'][0] = range(0, 5);
$fm['archive']['compress'][1] = array('-0', '-1', '-9');
$fm['archive']['compress'][2] = $fm['archive']['compress'][3] = $fm['archive']['compress'][4] = array(0);

?>
