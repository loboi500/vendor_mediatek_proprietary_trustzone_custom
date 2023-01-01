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
my $isforce=1;
my $is_kernel_v2=0;

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

  if($featureXml eq "sdsp_on.xml"){
    $featureXml = "sdsp_on_pl.xml";
  }
  if($featureXml eq "sdsp_off.xml"){
    $featureXml = "sdsp_off_pl.xml";
  }

  if($featureXml eq $ori_featureXml){
    print "Keep the same file:$featureXml\n";
  }else{
    print "Change from $ori_featureXml to $featureXml\n";
  }

  if((!-e $featureXml)){
    print "Can not find config file $featureXml\n";
    &usage();
  }
}

if(($kernel eq "kernel-4.4") || ($kernel eq "kernel-4.9") || ($kernel eq "kernel-4.14")){
  $is_kernel_v2=0;
}
else{
  $is_kernel_v2=1;
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
if($is_kernel_v2 eq 1){
  &readConfig($doc,"KernelV2Config",\%kernelV2ConfigFeature);
  &readConfig($doc,"KernelV2DebugConfig",\%kernelV2DebugConfigFeature);
}else{
  &readConfig($doc,"KernelConfig",\%kernelConfigFeature);
  &readConfig($doc,"KernelDebugConfig",\%kernelDebugConfigFeature);
}
$doc->dispose;

&changeProjectConfig(\%projectConfigFeature);
&changePreloaderConfig(\%preloaderConfigFeature);
&changeTrustzoneConfig(\%trustzoneConfigFeature);
&changeLKConfig(\%lkConfigFeature);
if($is_kernel_v2 eq 1){
  print "Modify for kernel version v2.\n";
  &changeKernelConfig(\%kernelV2ConfigFeature,\%kernelV2DebugConfigFeature);
}
else{
  &changeKernelConfig(\%kernelConfigFeature,\%kernelDebugConfigFeature);
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
  my $hit = 0;
  my $update_defconfig = "./device/mediatek/build/build/tools/update_defconfig.py ";
  my $kernelConfig = $path."/".$kernel."/arch/arm/configs/".$project."_defconfig";
  my $kernelDebugConfig = $path."/".$kernel."/arch/arm/configs/".$project."_debug_defconfig";
  my $kernel64Config = $path."/".$kernel."/arch/arm64/configs/".$project."_defconfig";
  my $kernel64DebugConfig = $path."/".$kernel."/arch/arm64/configs/".$project."_debug_defconfig";
  my $kernelConfigChecker = $update_defconfig.$kernel."/arch/arm/configs ".$project." dummy_config_txt savedefconfig";
  my $kernel64ConfigChecker = $update_defconfig.$kernel."/arch/arm64/configs ".$project." dummy_config.txt savedefconfig";
  my $kernelDir = $path."/".$kernel;
  my $pwd = cwd();
  if(-e $kernelConfig){
    &changeKconfig($kernelConfig,$rConfigs);
    &changeKconfig($kernelDebugConfig,$rDebugConfigs);
    chdir($path);
	local $dir = getcwd;
    print "kconfig dir is $dir\n";
	system("touch dummy_config.txt");
    print "$kernelConfigChecker\n";
    system($kernelConfigChecker);
	system("rm -rf dummy_config.txt");
    chdir($pwd);
	local $dir = getcwd;
    print "current dir is $dir\n";
    $hit = 1;
  }
  if(-e $kernel64Config){
    &changeKconfig($kernel64Config,$rConfigs);
    &changeKconfig($kernel64DebugConfig,$rDebugConfigs);
    chdir($path);
	local $dir = getcwd;
    print "kconfig dir is $dir\n";
	system("touch dummy_config.txt");
    print "$kernel64ConfigChecker\n";
    system($kernel64ConfigChecker);
	system("rm -rf dummy_config.txt");
    chdir($pwd);
	local $dir = getcwd;
    print "current dir is $dir\n";
    $hit = 1;
  }
  die "Can not find $kernelConfig and ${kernel64Config}" unless($hit);
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
  my $legacy_feat1 = "export MTK_GZ_SUPPORT_SDSP";

  print "Modify file $file\n";
  open MAKEFILE,"<$file" or die "Can not open $file\n";
  while(<MAKEFILE>){
    my $line = $_;
    chomp $line;

    if ((index($line, $legacy_comment) != -1) ||
        (index($line, $legacy_feat1) != -1)) {
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
Usage: ./changeSDSP.pl --config=ConfigFile --project=Project --kernel=Kernel_Version

Options:
  --config      : config file.
  --project     : project to change.
  --kernel      : kernel version to change.

Example:

=========================================================================================
====== MTK SDSP ====================================================================
=========================================================================================
Turn on SDSP config options
  ./changeSDSP.pl --config=sdsp_on.xml --project=k79v1_64 --kernel=kernel-4.19

Turn off SDSP config options
  ./changeSDSP.pl --config=sdsp_off.xml --project=k79v1_64 --kernel=kernel-4.19

__END_OF_USAGE

  exit 1;
}
