#!/usr/bin/perl
use Getopt::Long;
use XML::DOM;
use Data::Dumper;
use File::Copy;
use Cwd;

my $featureXml= "";
my $project= "";
my $base_project= "";
my $path="./../../../../../../../..";
my $kernel="";
my $isbackup;
my $have_gz_file=$path."/vendor/mediatek/internal/gz_enable";
my $have_gz_enable=0;
my $isforce=0;
my $kernel_category=0;

my %androidConfig;

&GetOptions(
    "config=s" => \$featureXml,
    "project=s" => \$project,
    "base_project=s" => \$base_project,
    "path=s" => \$path,
    "kernel=s" => \$kernel,
    "backup" => \$isbackup,
    "force" => \$isforce,
);

if(($featureXml eq "" ) || (!-e $featureXml)){
    print "Can not find config file $featureXml\n";
    &usage();
}
if($project =~ /^\s*$/){
    print "project is empty $project\n";
    &usage();
}

my $company = getCompany($project);
my $platform_name = getPlatform();

if($isforce){
  print "Force use original XML file:$featureXml\n";
}else{
  my $ori_featureXml = $featureXml;

  if($featureXml eq "geniezone_on.xml"){
    $featureXml = "geniezone_on_pl.xml";
  }
  if($featureXml eq "geniezone_off.xml"){
    $featureXml = "geniezone_off_pl.xml";
  }
  if($featureXml eq "gz_nebula_on.xml"){
    $featureXml = "gz_nebula_on_pl.xml";
  }
  if($featureXml eq "gz_nebula_off.xml"){
    $featureXml = "gz_nebula_off_pl.xml";
  }

  if($featureXml eq $ori_featureXml){
    print "Keep the same file:$featureXml\n";
  }else{
    print "Change from $ori_featureXml to $featureXml\n";
  }

  if((-e $have_gz_file)){
    print "have_gz_file is existed: $have_gz_file\n";
    $have_gz_enable=1;
  }else{
    print "have_gz_file is not existed: $have_gz_file\n";
    $have_gz_enable=0;
  }

  if((!-e $featureXml)){
    print "Can not find config file $featureXml\n";
    &usage();
  }
}

if($kernel eq "kernel-4.14"){
  $kernel_category=1;
}

if($kernel eq "kernel-4.19"){
  $kernel_category=2;
}

if(($kernel eq "kernel-5.4") || ($kernel eq "kernel-5.10")){
  $kernel_category=3;
}

if($kernel eq "gki"){
  $kernel_category=4;
}

my $dom_parser = new XML::DOM::Parser;
my $doc = $dom_parser->parsefile("./".$featureXml);
my %projectConfigFeature;
my %trustzoneConfigFeature;
my %lkConfigFeature;
my %preloaderConfigFeature;
my %kernelConfigFeature;
my %kernelDebugConfigFeature;
my %kernelV2ConfigFeature;
my %kernelV2DebugConfigFeature;
&readConfig($doc,"ProjectConfig",\%projectConfigFeature);
&readConfig($doc,"TrustzoneConfig",\%trustzoneConfigFeature);
&readConfig($doc,"LKConfig",\%lkConfigFeature);
&readConfig($doc,"PreloadConfig",\%preloaderConfigFeature);
if($kernel_category ne 0){
  if($kernel_category eq 1){
    &readConfig($doc,"KernelConfig",\%kernelConfigFeature);
    &readConfig($doc,"KernelDebugConfig",\%kernelDebugConfigFeature);
  }elsif($kernel_category eq 2){
    &readConfig($doc,"KernelV2Config",\%kernelV2ConfigFeature);
    &readConfig($doc,"KernelV2DebugConfig",\%kernelV2DebugConfigFeature);
  }elsif($kernel_category eq 3){
    &readConfig($doc,"KernelV3Config",\%kernelV3ConfigFeature);
    &readConfig($doc,"KernelV3DebugConfig",\%kernelV3DebugConfigFeature);
  }else{
  }
}
$doc->dispose;

&changeProjectConfig(\%projectConfigFeature);
&changePreloaderConfig(\%preloaderConfigFeature);
&changeTrustzoneConfig(\%trustzoneConfigFeature);
#&changeLKConfig(\%lkConfigFeature);
if($kernel_category ne 0){
  if($kernel_category eq 1){
    print "Modify for kernel version v1.\n";
    &changeKernelConfig(\%kernelConfigFeature,\%kernelDebugConfigFeature);
  }
  elsif($kernel_category eq 2){
    print "Modify for kernel version v2.\n";
    &changeKernelConfig(\%kernelV2ConfigFeature,\%kernelV2DebugConfigFeature);
  }
  elsif($kernel_category eq 3){
    print "Modify for kernel version v3.\n";
    &changeKernelConfig(\%kernelV3ConfigFeature,\%kernelV3DebugConfigFeature);
  }
  else{
    print "Modify for kernel version v4.(GKI) \n";
  }
}

print "Done all config\n";
exit 0;

sub getCompany {
  my $prjname = $_[0];
  my $line = `bash -c 'find $path/device -maxdepth 3 -type d -name $prjname -printf "%P"'`;
  if($line ne "") {
      my $company = (split('/', $line))[0];
      return $company;
  }
  else{
      return undef;
  }
}

sub getPlatform {
  my $projectConfigMakefile = $path."/device/".$company."/".$project."/ProjectConfig.mk";
  my $platform = getOptionValue($projectConfigMakefile, "MTK_PLATFORM");

  print "platform is $platform\n";
  return $platform;
}

sub changeKernelConfig{
  my $rConfigs = $_[0];
  my $rDebugConfigs = $_[1];

  my $cmd_updatedefconfig_head = "python device/mediatek/build/build/tools/update_defconfig.py ";

  my $hit = 0;
  my $kernelConfig = $path."/".$kernel."/arch/arm/configs/".$project."_defconfig";
  my $kernelDebugConfig = $path."/".$kernel."/arch/arm/configs/".$project."_debug_defconfig";
  my $kernel64Config = $path."/".$kernel."/arch/arm64/configs/".$project."_defconfig";
  my $kernel64DebugConfig = $path."/".$kernel."/arch/arm64/configs/".$project."_debug_defconfig";

  my $pwd = cwd();

# check then create option_file
  if(-e $path."/tmp_option_file"){
    unlink $path."/tmp_option_file";
  }
  &tmpOptionFile($path."/tmp_option_file", $rConfigs);

# do update_defconfig.py
  if(-e $kernelConfig and -e $path."/tmp_option_file"){
    $cmd_updatedefconfig = $cmd_updatedefconfig_head.$kernel."/arch/arm/configs ".$project." tmp_option_file savedefconfig";
    chdir($path);
    system($cmd_updatedefconfig);
    chdir($pwd);
    $hit = 1;
  }
  if(-e $kernel64Config and -e $path."/tmp_option_file"){
    $cmd_updatedefconfig = $cmd_updatedefconfig_head.$kernel."/arch/arm64/configs ".$project." tmp_option_file savedefconfig";
    chdir($path);
    system($cmd_updatedefconfig);
    chdir($pwd);
    $hit = 1;
  }

# remove option_file
  if(-e $path."/tmp_option_file"){
    unlink $path."/tmp_option_file";
  }

  die "Can not find $kernelConfig or ${kernel64Config}" unless($hit);
}

sub changeTrustzoneConfig{
  my $rConfigs = $_[0];
  my $makefile = $path."/vendor/mediatek/proprietary/trustzone/custom/build/project/".$project.".mk";
  if ((! -e $makefile) and ($base_project ne "")) {
    $makefile = $path."/vendor/mediatek/proprietary/trustzone/custom/build/project/".$base_project.".mk";
  }
  print "TrustzoneConfig=$makefile\n";
  &changeMakefileConfig($makefile,$rConfigs);
}

sub changeLKConfig{
  my $rConfigs = $_[0];
  my $makefile = $path."/vendor/mediatek/proprietary/bootable/bootloader/lk/project/".$project.".mk";
  if ((! -e $makefile) and ($base_project ne "")) {
    $makefile = $path."/vendor/mediatek/proprietary/bootable/bootloader/lk/project/".$base_project.".mk";
  }
  print "LKConfig=$makefile\n";
  &changeMakefileConfig($makefile,$rConfigs);
}

sub changePreloaderConfig{
  my $rConfigs = $_[0];
  my $makefile = $path."/vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/".$project."/".$project.".mk";
  if ((! -e $makefile) and ($base_project ne "")) {
    $makefile = $path."/vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/".$base_project."/".$base_project.".mk";
  }
  print "PreloaderConfig=$makefile\n";
  &changeMakefileConfig($makefile,$rConfigs);
  &changePreloaderExport($makefile,$rConfigs);
}

sub changeProjectConfig{
  my $rConfigs = $_[0];
  my $projectConfigMakefile = $path."/device/".$company."/".$project."/ProjectConfig.mk";
  &changeMakefileConfig($projectConfigMakefile,$rConfigs);
}

sub backup{
  my $file = $_[0];
  my $fileNew = $file.".bak";
  copy($file,$fileNew) or die "Copy $file fail: $!";
}

sub tmpOptionFile{
  my $tmp_option_file=$_[0];
  my $rConfigs=$_[1];
  my @features = sort keys %{$rConfigs};
  open (OPTIONFILE, "> ".$tmp_option_file) or die "$!";
  for my $feature(@features){
    if($rConfigs->{$feature} eq "is not set"){
      print OPTIONFILE "# $feature is not set"."\n";
    }
    else{
      print OPTIONFILE $feature."=".$rConfigs->{$feature}."\n";
    }
  }
  close OPTIONFILE;
}

sub changeMakefileConfig{
  my $file=$_[0];
  my $rConfigs=$_[1];
  my @features = sort keys %{$rConfigs};
  my $fileContent ="";
  my %hitFeature;
  my $withColon = "";
  print "Modify file $file\n";
  print Dumper($rConfigs);
  open MAKEFILE,"<$file" or die "Can not open $file\n";
  while(<MAKEFILE>){
    my $line = $_;
    chomp $line;
    for my $feature(@features){
      if($line =~ /^\s*$feature\s*(:?)=/){
        $withColon = ":" if($1 eq ":");
        my $newLine;
        if ($withColon ne "") {
            $newLine = $feature." ".$withColon."= ".$rConfigs->{$feature};
        } else {
            $newLine = $feature." = ".$rConfigs->{$feature};
        }
        print "ORG:".$line."\n";
        print "NEW:".$newLine."\n";
        if($rConfigs->{$feature} eq "delete_entry"){
          print "delete this entry: ".$line."\n";
          $line = "";
        }elsif((!$isforce) &&
               ($feature eq "HAVE_MTK_GENIEZONE") && ($have_gz_enable eq 1)){
          print "remove this entry: ".$line."\n";
          $line = "";
        }else{
          $line = $newLine;
        }
        $hitFeature{$feature}=1;
        last;
      }
    }
    if($line ne ""){
      $fileContent .= $line."\n";
    }
  }
  close MAKEFILE;
  for my $feature(@features){
    my $line;
    if(! defined $hitFeature{$feature}){
      $line = $feature.$withColon."=".$rConfigs->{$feature}."\n";
      if((!$isforce) &&
          ($feature eq "HAVE_MTK_GENIEZONE") && ($have_gz_enable eq 1)){
        print "skip this entry: ".$line."\n";
      }elsif($rConfigs->{$feature} ne "delete_entry"){
        print "NEW:".$line;
        $fileContent .= $line;
      }
    }
  }
  &backup($file) if($isbackup);
  open MAKEFILE,">$file" or die "Can not open $file\n";
  print MAKEFILE $fileContent;
  close MAKEFILE;
}

sub changePreloaderExport {
  my $file=$_[0];
  my $rConfigs=$_[1];
  my @features = sort keys %{$rConfigs};
  my $fileContent ="";
  my %hitFeature;
  my $withColon = "";
  my $found_marker = 0;

  my $marker = "export";
  my $markerNewLine;
  my $legacy_comment = "PLEASE ADD EXPORT BELOW THIS LINE";
  my $legacy_feat1 = "export MTK_ENABLE_GENIEZONE";
  my $legacy_feat2 = "export MTK_NEBULA_VM_SUPPORT";

  print "Modify file $file\n";
  open MAKEFILE,"<$file" or die "Can not open $file\n";
  while(<MAKEFILE>){
    my $line = $_;
    chomp $line;

    if ((index($line, $legacy_comment) != -1) ||
        (index($line, $legacy_feat1) != -1) ||
        (index($line, $legacy_feat2) != -1)) {
          print "delete this line: ".$line."\n";
          next;
    }

    if($line =~ /^\s*$marker\s*(:?) /){
      $markerNewLine = $line;

      for my $feature(@features){
        if (index($line, $feature) != -1) {
          print "$feature is already exported\n";
        } else {
          $markerNewLine = $markerNewLine." ".$feature;
        }
      }

      print "ORG:".$line."\n";
      print "NEW:".$markerNewLine."\n";
      $found_marker = 1;
    }else{
      if($line ne ""){
        $fileContent .= $line."\n";
      }
    }
  }
  if ($found_marker eq 1) {
    $fileContent .= $markerNewLine."\n";
  }
  close MAKEFILE;
  &backup($file) if($isbackup);
  open MAKEFILE,">$file" or die "Can not open $file\n";
  print MAKEFILE $fileContent;
  close MAKEFILE;
}

sub readConfig{
  my $doc = $_[0];
  my $configName = $_[1];
  my $rConfigs = $_[2];
  my $configNodes = $doc->getElementsByTagName($configName)->item(0)->getElementsByTagName("config");
  my $n = $configNodes->getLength;
  for (my $i = 0; $i < $n; $i++) {
    my $feature=$configNodes->item($i)->getAttribute("feature");
    my $value=$configNodes->item($i)->getAttribute("value");
    $rConfigs->{$feature}=$value;
  }
  return 0;
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub getOptionValue{
  my $file=$_[0];
  my $search_str=$_[1];
  my $key;
  my $value;

  open MAKEFILE,"<$file" or die "Can not open $file\n";
  while(<MAKEFILE>){
    my $line = $_;
    chomp $line;
    if($line =~ /^\s*$search_str\s*(:?)=/){
      print "DBG: ".$line."\n";
      ($key, $value) = split /=/, $line;
      #print "key=".trim($key)."\n";
      #print "value=".trim($value)."\n";
    }
  }
  close MAKEFILE;

  return trim($value);
}

sub usage{
  warn << "__END_OF_USAGE";
Usage: ./changeGZ.pl --config=ConfigFile --project=Project --kernel=Kernel_Version [--force]

Options:
  --config      : config file.
  --project     : project to change.
  --kernel      : kernel version to change.
  --force	: force to change the configs.

Example:

=========================================================================================
====== MTK GENIEZONE ====================================================================
=========================================================================================
Turn on GENIEZONE config options
  ./changeGZ.pl --config=geniezone_on.xml --project=k71v1_64_bsp --kernel=kernel-4.4

Turn off GENIEZONE config options
  ./changeGZ.pl --config=geniezone_off.xml --project=k71v1_64_bsp --kernel=kernel-4.4

__END_OF_USAGE

  exit 1;
}
