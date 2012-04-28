#!/usr/bin/pugs

system q(pugs -MWWW::Kontent -e'WWW::Kontent::make_root');

system qq(./import_page.p6 'WWW::Kontent 0.02' < import/$_) 
	for < root.yml kontent.yml settings.yml
	default-user.yml html-styles.yml html-template.yml site-name.yml uri-prefix.yml
	users.yml users-anonymous.yml users-contributors.yml users-root.yml
	help.yml help-concepts.yml help-concretes.yml help-create.yml help-customize.yml
	help-edit.yml help-export-import.yml help-fidelius.yml help-k_manip.yml 
	help-kolophon.yml help-navigating.yml help-user.yml help-xml.yml
	code.yml code-change-user.yml >;
