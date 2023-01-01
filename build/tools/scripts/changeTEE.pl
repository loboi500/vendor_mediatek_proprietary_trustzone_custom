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
my $kernel_category=0;
my %androidConfig;

&GetOptions(
    "config=s" => \$featureXml,
    "project=s" => \$project,
    "base_project=s" => \$base_project,
    "path=s" => \$path,
    "kernel=s" => \$kernel,
    "backup" => \$isbackup,
);

if(($featureXml eq "" ) || (!-e $featureXml)){
    print "Can not find config file $featureXml\n";
    &usage();
}
if($project =~ /^\s*$/){
    print "project is empty $project\n";
    &usage();
}

if (($kernel eq "kernel-5.4") || ($kernel eq "kernel-5.10")) {
  $kernel_category=1;
}

my $company = getCompany($project);

my $dom_parser = new XML::DOM::Parser;
my $doc = $dom_parser->parsefile("./".$featureXml);
my %projectConfigFeature;
my %trustzoneConfigFeature;
my %lkConfigFeature;
my %preloaderConfigFeature;
my %kernelConfigFeature;
my %kernelDebugConfigFeature;
my %kernelV1ConfigFeature;
my %kernelV1DebugConfigFeature;
my %deviceConfigFeature;
&readConfig($doc,"ProjectConfig",\%projectConfigFeature);
&readConfig($doc,"TrustzoneConfig",\%trustzoneConfigFeature);
&readConfig($doc,"LKConfig",\%lkConfigFeature);
&readConfig($doc,"PreloadConfig",\%preloaderConfigFeature);
if ($kernel_category eq 1) {
  &readConfig($doc,"KernelV1Config",\%kernelV1ConfigFeature);
  &readConfig($doc,"KernelV1DebugConfig",\%kernelV1DebugConfigFeature);
} else {
  &readConfig($doc,"KernelConfig",\%kernelConfigFeature);
  &readConfig($doc,"KernelDebugConfig",\%kernelDebugConfigFeature);
}
&readConfig($doc,"DeviceConfig",\%deviceConfigFeature);
$doc->dispose;

&changeProjectConfig(\%projectConfigFeature);
&changePreloaderConfig(\%preloaderConfigFeature);
&changeTrustzoneConfig(\%trustzoneConfigFeature);
&changeLKConfig(\%lkConfigFeature);
if ($kernel_category eq 1) {
  print "Modify for kernel version v1.\n";
  &changeKernelConfig(\%kernelV1ConfigFeature,\%kernelV1DebugConfigFeature);
} else {
  print "Modify for kernel version v0.\n";
  &changeKernelConfig(\%kernelConfigFeature,\%kernelDebugConfigFeature);
}
&changeDeviceConfig(\%deviceConfigFeature);

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

sub changeDeviceConfig{
  my $rConfigs = $_[0];
  my $makefile = $path."/device/".$company."/".$project."/device.mk";

  print "DeviceConfig=$makefile\n";
  &changeMakefileConfig($makefile,$rConfigs);
}

sub changeKernelConfig{
  my $rConfigs = $_[0];
  my $rDebugConfigs = $_[1];
  my $hit = 0;
  my $pwd = cwd();
  my $cmd_updatedefconfig_head = "python device/mediatek/build/build/tools/update_defconfig.py ";
  my $kernelConfig = $path."/".$kernel."/arch/arm/configs/".$project."_defconfig";
  my $kernelDebugConfig = $path."/".$kernel."/arch/arm/configs/".$project."_debug_defconfig";
  my $kernel64Config = $path."/".$kernel."/arch/arm64/configs/".$project."_defconfig";
  my $kernel64DebugConfig = $path."/".$kernel."/arch/arm64/configs/".$project."_debug_defconfig";

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
  if (! -e $makefile) {
    $makefile = $path."/bootable/bootloader/preloader/custom/".$project."/".$project.".mk";
  }
  if ((! -e $makefile) and ($base_project ne "")) {
    $makefile = $path."/bootable/bootloader/preloader/custom/".$base_project."/".$base_project.".mk";
  }
  print "PreloaderConfig=$makefile\n";
  &changeMakefileConfig($makefile,$rConfigs);

  my $cust_bldr_mak = $path."/vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/".$project."/cust_bldr.mak";
  if ((! -e $cust_bldr_mak) and ($base_project ne "")) {
    $cust_bldr_mak = $path."/vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/".$base_project."/cust_bldr.mak";
  }
  if (! -e $cust_bldr_mak) {
    $cust_bldr_mak = $path."/bootable/bootloader/preloader/custom/".$project."/cust_bldr.mak";
  }
  if ((! -e $cust_bldr_mak) and ($base_project ne "")) {
    $cust_bldr_mak = $path."/bootable/bootloader/preloader/custom/".$base_project."/cust_bldr.mak";
  }
  print "PreloaderCustBldrMak=$cust_bldr_mak\n";
  &changePreloaderCustBldrMak($cust_bldr_mak,$rConfigs);
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

sub changeKconfig{
  my $file=$_[0];
  my $rConfigs=$_[1];
  my @features = sort keys %{$rConfigs};
  my $fileContent ="";
  my %hitFeature;
  print "Modify file $file\n";
  print Dumper($rConfigs);
  open KERNELCONFIG,"<$file" or die "Can not open $file\n";
  while(<KERNELCONFIG>){
    my $line = $_;
    chomp $line;
    for my $feature(@features){
      if(($line =~ /^\s*$feature\s*=/) || ($line =~ /^\#\s*$feature is not set/)){
        my $newLine;
        if($rConfigs->{$feature} eq "is not set"){
          $newLine = "# $feature is not set";
        }
        else{
          $newLine = $feature."=".$rConfigs->{$feature};
        }
        print "ORG:".$line."\n";
        print "NEW:".$newLine."\n";
        $line = $newLine;
        $hitFeature{$feature}=1;
        last;
      }
    }
    $fileContent .= $line."\n";
  }
  close KERNELCONFIG;
  for my $feature(@features){
    if(! defined $hitFeature{$feature}){
      my $line;
      if($rConfigs->{$feature} eq "is not set"){
        $line = "# $feature is not set"."\n";
      }
      else{
        $line = $feature."=".$rConfigs->{$feature}."\n";
      }
      print "NEW:".$line;
      $fileContent .= $line;
    }
  }
  &backup($file) if($isbackup);
  open KERNELCONFIG,">$file" or die "Can not open $file\n";
  print KERNELCONFIG $fileContent;
  close KERNELCONFIG;
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
        }
        else{
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
      if($rConfigs->{$feature} ne "delete_entry"){
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

sub changePreloaderCustBldrMak {
  my $file=$_[0];
  my $rConfigs=$_[1];
  my $marker = "##### TEE >PLEASE ADD CONFIGS ABOVE THIS LINE< TEE #####";
  my $body = <<'__END_OF_TEES';
ifeq ($(strip $(MTK_TEE_SUPPORT)),yes)
  CFG_TEE_SUPPORT = 1
  ifeq ($(strip $(TRUSTONIC_TEE_SUPPORT)),yes)
    CFG_TRUSTONIC_TEE_SUPPORT = 1
  else
    CFG_TRUSTONIC_TEE_SUPPORT = 0
  endif
  ifeq ($(strip $(MICROTRUST_TEE_SUPPORT)),yes)
    CFG_MICROTRUST_TEE_SUPPORT = 1
  else
    CFG_MICROTRUST_TEE_SUPPORT = 0
  endif
   ifeq ($(strip $(MICROTRUST_TEE_LITE_SUPPORT)),yes)
    CFG_MICROTRUST_TEE_LITE_SUPPORT = 1
  else
    CFG_MICROTRUST_TEE_LITE_SUPPORT = 0
  endif
  ifeq ($(strip $(WATCHDATA_TEE_SUPPORT)),yes)
    CFG_WATCHDATA_TEE_SUPPORT = 1
  else
    CFG_WATCHDATA_TEE_SUPPORT = 0
  endif
  ifeq ($(strip $(MTK_GOOGLE_TRUSTY_SUPPORT)),yes)
    CFG_GOOGLE_TRUSTY_SUPPORT = 1
  else
    CFG_GOOGLE_TRUSTY_SUPPORT = 0
  endif
  ifeq ($(strip $(TRUSTKERNEL_TEE_SUPPORT)),yes)
    CFG_TRUSTKERNEL_TEE_SUPPORT = 1
  else
    CFG_TRUSTKERNEL_TEE_SUPPORT = 0
  endif
else
  CFG_TEE_SUPPORT = 0
  CFG_TRUSTONIC_TEE_SUPPORT = 0
  CFG_MICROTRUST_TEE_SUPPORT = 0
  CFG_MICROTRUST_TEE_LITE_SUPPORT = 0
  CFG_WATCHDATA_TEE_SUPPORT = 0
  CFG_GOOGLE_TRUSTY_SUPPORT = 0
  CFG_TRUSTKERNEL_TEE_SUPPORT = 0
endif
$(warning CFG_TEE_SUPPORT=$(CFG_TEE_SUPPORT))
$(warning CFG_TRUSTONIC_TEE_SUPPORT=$(CFG_TRUSTONIC_TEE_SUPPORT))
$(warning CFG_MICROTRUST_TEE_SUPPORT=$(CFG_MICROTRUST_TEE_SUPPORT))
$(warning CFG_WATCHDATA_TEE_SUPPORT=$(CFG_WATCHDATA_TEE_SUPPORT))
$(warning CFG_GOOGLE_TRUSTY_SUPPORT=$(CFG_GOOGLE_TRUSTY_SUPPORT))
$(warning CFG_MICROTRUST_TEE_SUPPORT=$(CFG_MICROTRUST_TEE_SUPPORT))
$(warning CFG_MICROTRUST_TEE_LITE_SUPPORT=$(CFG_MICROTRUST_TEE_LITE_SUPPORT))
__END_OF_TEES

  my $found_marker = 0;
  my %hitFeature;
  my $withColon = "";
  print "Modify file $file\n";

  print Dumper($rConfigs);
  open MAKEFILE,"<$file" or die "Can not open $file\n";
  while(<MAKEFILE>){
    my $line = $_;
    chomp $line;
    if($line =~ /^\s*$marker\s*/){
      print "Marker Found, $line\n";
      $found_marker = 1;
      last;
    }
  }
  close MAKEFILE;
  &backup($file) if($isbackup);
  if ($found_marker eq 0) {
    open MAKEFILE,">>$file" or die "Can not open $file\n";
    print MAKEFILE "\n\n".(($marker."\n") x 1).$body;
    close MAKEFILE;
  }
}

sub usage{
  warn << "__END_OF_USAGE";
Usage: ./changeTrusty.pl --config=ConfigFile --project=Project --kernel=Kernel_Version

Options:
  --config      : config file.
  --project     : project to release.

Example:

=========================================================================================
====== TRUSTONIC TEE ====================================================================
=========================================================================================
Turn on TRUSTONIC config options
  ./changeTEE.pl --config=trustonicArmv8_on.xml --project=k53v1_64 --kernel=kernel-3.18
  ./changeTEE.pl --config=trustonicArmv7_on.xml --project=k80hd --kernel=kernel-3.18

Turn off TRUSTONIC config options
  ./changeTEE.pl --config=trustonicArmv8_off.xml --project=k53v1_64 --kernel=kernel-3.18
  ./changeTEE.pl --config=trustonicArmv7_off.xml --project=k80hd --kernel=kernel-3.18

=========================================================================================
====== GOOGLE TRUSTY ====================================================================
=========================================================================================
Turn on TRUSTY config options
  ./changeTEE.pl --config=trustyArmv8_on.xml --project=k53v1_64 --kernel=kernel-3.18
  ./changeTEE.pl --config=trustyArmv7_on.xml --project=k80hd --kernel=kernel-3.18

Turn off TRUSTY config options
  ./changeTEE.pl --config=trustyArmv8_off.xml --project=k53v1_64 --kernel=kernel-3.18
  ./changeTEE.pl --config=trustyArmv7_off.xml --project=k80hd --kernel=kernel-3.18

=========================================================================================
====== MICROTRUST TEEI ==================================================================
=========================================================================================
Turn on MICROTRUST config options
  ./changeTEE.pl --config=teeiArmv8_on.xml --project=k53v1_64 --kernel=kernel-3.18

Turn off MICROTRUST config options
  ./changeTEE.pl --config=teeiArmv8_off.xml --project=k53v1_64 --kernel=kernel-3.18

=========================================================================================
=========================================================================================

=========================================================================================
====== WATCHDATA TEE ====================================================================
=========================================================================================
Turn on WATCHDATA config options
  ./changeTEE.pl --config=watchdataArmv8_on.xml --project=k63v2_64_bsp --kernel=kernel-4.4

Turn off WATCHDATA config options
  ./changeTEE.pl --config=watchdataArmv8_off.xml --project=k63v2_64_bsp --kernel=kernel-4.4

=========================================================================================
=========================================================================================

=========================================================================================
====== WATCHDATA TEE ====================================================================
=========================================================================================
Turn on WATCHDATA config options
  ./changeTEE.pl --config=tkcoreArmv8_on.xml --project=k61v1_64_bsp --kernel=kernel-4.9

Turn off WATCHDATA config options
  ./changeTEE.pl --config=tkcoreArmv8_off.xml --project=k61v1_64_bsp --kernel=kernel-4.9

=========================================================================================
=========================================================================================

__END_OF_USAGE

  exit 1;
}
