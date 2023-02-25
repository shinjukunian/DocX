Pod::Spec.new do |s|
  s.name             = 'DocX'
  s.version          = '0.8.8'
  s.summary          = 'Convert NSAttributedString / AttributedString to .docx Word files on iOS and macOS.'
  s.homepage         = 'https://github.com/shinjukunian/DocX'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Morten' => 'morten@telethon.jp' }
  s.source           = { :git => 'https://github.com/shinjukunian/DocX.git', :tag => s.version }
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.osx.deployment_target  = '10.13'
  s.source_files = 'DocX/**/*.swift'
      
  s.dependency 'ZIPFoundation', '~> 0.9.16'
  s.dependency 'AEXML_DocX' , '~> 4.6.3'
  s.resources = 'DocX/blank'
        
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'DocXTests/*.swift'
    test_spec.resources = ['DocXTests/lenna.md', 'DocXTests/lenna.png', 'DocXTests/Picture1.png', 'DocXTests/styles.xml', 'DocXTests/blank.docx']
  end
end

