/* 
The Script will enable multiple Django sites along with site configurations. 

`GetSiteNames`   :   Initialize  the site names based on paramater. example: prod,int,bvt
`GetSiteIds`     :   Return Site id for Django Sites if already exist. Create Site and return Site id if doesn't exist.
`GetSiteconfigs` :   Get site configurations for all the four sites based on the provided environment paramater.
`CreateorUpdateSiteConfigs` : Update site configurations if already exist. else, create new entry for site configurations.

PARAMETERS: 
`env` : An Optional parameter can be passed based on the deploying environment. Defaulted to BVT 


Script Execution Example :  sudo mysql edxapp  -e"set @env='prod'; `cat name_of_file.sql`" 

*/

-- Drop Procedures if Exist
DROP PROCEDURE IF EXISTS GetSiteNames;
DROP PROCEDURE IF EXISTS GetSiteIds;
DROP PROCEDURE IF EXISTS GetSiteconfigs;
DROP PROCEDURE  IF EXISTS CreateorUpdateSiteConfigs;



DELIMITER $$
CREATE PROCEDURE GetSiteNames(
    IN  environment VARCHAR(50),
    INOUT openedx_site  varchar(50), 
    INOUT courses_site varchar(50),
    INOUT preview_site  varchar(50), 
    INOUT cms_site varchar(50))
BEGIN
IF environment = 'prod' THEN 
    SET openedx_site = 'openedx.microsoft.com' ;
    SET courses_site = 'courses.microsoft.com';
    SET preview_site = 'preview.prod.oxa.microsoft.com';
    SET cms_site = 'cms.prod.oxa.microsoft.com';
ELSEIF  environment = 'int' THEN 
    SET openedx_site = 'openedx.int.oxa.microsoft.com' ;
    SET courses_site = 'courses.int.oxa.microsoft.com';
    SET preview_site = 'preview.int.oxa.microsoft.com';
    SET cms_site = 'cms.int.oxa.microsoft.com';
ELSE 
    SET openedx_site = 'openedx.bvt.oxa.microsoft.com' ;
    SET courses_site = 'courses.bvt.oxa.microsoft.com';
    SET preview_site = 'preview.bvt.oxa.microsoft.com';
    SET cms_site = 'cms.bvt.oxa.microsoft.com';
END IF ;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE GetSiteIds(
    IN  openedx_site VARCHAR(50),
    IN  courses_site VARCHAR(50),
    IN  preview_site VARCHAR(50),
    IN  cms_site VARCHAR(50),
    INOUT  openedx_site_id VARCHAR(50),
    INOUT  courses_site_id VARCHAR(50),
    INOUT  preview_site_id VARCHAR(50),
    INOUT  cms_site_id VARCHAR(50))
BEGIN

--
-- Get site id for openedx site 
--
IF exists (select distinct(id) FROM django_site WHERE domain = openedx_site) THEN
    SET openedx_site_id = (select distinct(id) FROM django_site WHERE domain = openedx_site);
ELSE 
    UPDATE django_site set domain=openedx_site  WHERE id=1;
    UPDATE django_site set name=openedx_site  WHERE id=1;
    SET openedx_site_id = (select distinct(id) FROM django_site WHERE domain = openedx_site);
END IF ;

--
-- Get site id for courses site 
--
IF exists (select distinct(id) FROM django_site WHERE domain = courses_site) THEN
    SET courses_site_id = (select distinct(id) FROM django_site WHERE domain = courses_site);
ELSE 
    INSERT into django_site (domain,name) VALUES (courses_site,courses_site);
    SET courses_site_id = (select distinct(id) FROM django_site WHERE domain = courses_site);
END IF ;

--
-- Get site id for preview site 
--
IF exists (select distinct(id) FROM django_site WHERE domain = preview_site) THEN
    SET preview_site_id = (select distinct(id) FROM django_site WHERE domain = preview_site);
ELSE 
    INSERT into django_site (domain,name) VALUES (preview_site,preview_site);
    SET preview_site_id = (select distinct(id) FROM django_site WHERE domain = preview_site);
END IF ;

--
-- Get site id for cms site 
--
IF exists (select distinct(id) FROM django_site WHERE domain = cms_site) THEN
    SET cms_site_id = (select distinct(id) FROM django_site WHERE domain = cms_site);
ELSE 
    INSERT into django_site (domain,name) VALUES (cms_site,cms_site);
    SET cms_site_id = (select distinct(id) FROM django_site WHERE domain = cms_site);
END IF ;

END $$

DELIMITER ;


DELIMITER $$
CREATE PROCEDURE GetSiteconfigs(
    IN  environment VARCHAR(50),
    INOUT openedx_config_json  LONGTEXT, 
    INOUT courses_config_json LONGTEXT,
    INOUT preview_config_json  LONGTEXT, 
    INOUT cms_config_json LONGTEXT)
BEGIN
--
-- Get site configs based on the environment paramater 
--
IF environment = 'prod' THEN 
    SET openedx_config_json = '{\"course_org_filter\":\"Microsoft\",\"ENABLE_THIRD_PARTY_AUTH\":true,\"LMS_BASE\":\"openedx.microsoft.com\",\"PREVIEW_LMS_BASE\":\"preview.prod.oxa.microsoft.com\",\"SITE_NAME\":\"openedx.microsoft.com\",\"LMS_ROOT_URL\":\"https://openedx.microsoft.com\",\"external_login_api\":\"https://api.prod.mlxma.microsoft.com/api/v2.0/Authentication/ExternalLogin?Provider=RPS&PartnerName=OXA&RedirectUri=\",\"ENABLE_COMBINED_LOGIN_REGISTRATION\":true,\"ENABLE_COMBINED_LOGIN_REGISTRATION_FOOTER\":true,\"ENABLE_MSA_MIGRATION\":true,\"ENFORCE_PASSWORD_POLICY\":false}';
    SET courses_config_json = '{\"course_org_filter\":\"ELMS\",\"ENABLE_THIRD_PARTY_AUTH\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"course_email_template_name\":\"courses.template\",\"SITE_NAME\":\"courses.microsoft.com\",\"RESTRICT_COURSES_API\":true,\"LMS_ROOT_URL\":\"https://courses.microsoft.com\",\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\",\"^api/courses/v1/courses\",\"^oauth2/access_token\",\"^api/enrollment/v1/enrollment\",\"^api/mobile/v0.5/my_user_info.*$\",\"^api/mobile/v0.5/users.*$\",\"^api/grades/v0/course_grade.*$\"],\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"}}';
    SET preview_config_json = '{\"course_org_filter\":\"Microsoft\",\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY\":true,\"RESTRICT_COURSES_API\":true,\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\"]}';
    SET cms_config_json = '{\"ENABLE_MSA_MIGRATION\":false,\"PREVIEW_LMS_BASE\":\"preview.prod.oxa.microsoft.com\",\"ENABLE_AUTO_LOGIN\":true}';
ELSEIF environment = 'int' THEN
    SET openedx_config_json = '{\"course_org_filter\":\"Microsoft\",\"ENABLE_MSA\":true,\"ENABLE_ACCOUNT_DELETION\":false,\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true,\"ENABLE_CUSTOM_AUTH\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"RESTRICTED_DOMAIN\":\"@microsoft.com\",\"LMS_BASE\":\"openedx.bvt.oxa.microsoft.com\",\"PREVIEW_LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"SITE_NAME\":\"openedx.bvt.oxa.microsoft.com\",\"LMS_ROOT_URL\":\"https://openedx.bvt.oxa.microsoft.com\",\"REGISTRATION_EMAIL_PATTERNS_ALLOWED\":[\"(?i)^(?:(?!(microsoft.com)).)+$\"],\"external_login_api\":\"https://api.bvt.mlxma.microsoft.com/api/v2.0/AuTHENtication/ExternalLogin?Provider=RPS&PartnerName=OXA&RedirectUri=\",\"ENABLE_COMBINED_LOGIN_REGISTRATION\":true,\"ENABLE_COMBINED_LOGIN_REGISTRATION_FOOTER\":true,\"ENABLE_MSA_MIGRATION\":true,\"ONLY_MSA_LOGIN\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"SOCIAL_AUTH_REDIRECT_IS_HTTPS\":true,\"REDIRECT_IS_HTTPS\":true,\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"},\"PREFERRED_THIRD_PARTY_AUTH_REDIRECT_URL\":\"/\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_TEXT\":\"Sign in\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"/auth/login/live\"}';
    SET courses_config_json = '{\"course_org_filter\":\"ELMS\",\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"LMS_ROOT_URL\":\"https://courses.bvt.oxa.microsoft.com\",\"SITE_NAME\":\"courses.bvt.oxa.microsoft.com\",\"course_email_template_name\":\"courses.template\",\"RESTRICT_COURSES_API\":true,\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\",\"^api/courses/v1/courses\",\"^api/grades/v1/course_grade.*$\",\"^oauth2/access_token\",\"^api/enrollment/v1/enrollment\",\"^api/mobile/v0.5/my_user_info.*$\",\"^api/mobile/v0.5/users.*$\",\"^api/grades/v0/course_grade.*$\"],\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"},\"COURSES_ARE_BROWSABLE\":false,\"PREFERRED_THIRD_PARTY_AUTH_REDIRECT_URL\":\"/\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_TEXT\":\"Sign in\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"/auth/login/azuread-oauth2\"}';
    SET preview_config_json = '{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"RESTRICT_COURSES_API\":true,\"course_org_filter\":\"Microsoft\",\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\"],\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"\"}';
    SET cms_config_json = '{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true,\"LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"LMS_ROOT_URL\":\"https://preview.bvt.oxa.microsoft.com\",\"PREVIEW_LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"ENABLE_AUTO_LOGIN\":true}';
ELSE
    SET openedx_config_json = '{\"course_org_filter\":\"Microsoft\",\"ENABLE_MSA\":true,\"ENABLE_ACCOUNT_DELETION\":false,\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true,\"ENABLE_CUSTOM_AUTH\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"RESTRICTED_DOMAIN\":\"@microsoft.com\",\"LMS_BASE\":\"openedx.bvt.oxa.microsoft.com\",\"PREVIEW_LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"SITE_NAME\":\"openedx.bvt.oxa.microsoft.com\",\"LMS_ROOT_URL\":\"https://openedx.bvt.oxa.microsoft.com\",\"REGISTRATION_EMAIL_PATTERNS_ALLOWED\":[\"(?i)^(?:(?!(microsoft.com)).)+$\"],\"external_login_api\":\"https://api.bvt.mlxma.microsoft.com/api/v2.0/AuTHENtication/ExternalLogin?Provider=RPS&PartnerName=OXA&RedirectUri=\",\"ENABLE_COMBINED_LOGIN_REGISTRATION\":true,\"ENABLE_COMBINED_LOGIN_REGISTRATION_FOOTER\":true,\"ENABLE_MSA_MIGRATION\":true,\"ONLY_MSA_LOGIN\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"SOCIAL_AUTH_REDIRECT_IS_HTTPS\":true,\"REDIRECT_IS_HTTPS\":true,\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"},\"PREFERRED_THIRD_PARTY_AUTH_REDIRECT_URL\":\"/\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_TEXT\":\"Sign in\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"/auth/login/live\"}';
    SET courses_config_json = '{\"course_org_filter\":\"ELMS\",\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"ENFORCE_PASSWORD_POLICY\":false,\"LMS_ROOT_URL\":\"https://courses.bvt.oxa.microsoft.com\",\"SITE_NAME\":\"courses.bvt.oxa.microsoft.com\",\"course_email_template_name\":\"courses.template\",\"RESTRICT_COURSES_API\":true,\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\",\"^api/courses/v1/courses\",\"^api/grades/v1/course_grade.*$\",\"^oauth2/access_token\",\"^api/enrollment/v1/enrollment\",\"^api/mobile/v0.5/my_user_info.*$\",\"^api/mobile/v0.5/users.*$\",\"^api/grades/v0/course_grade.*$\"],\"REGISTRATION_EXTRA_FIELDS\":{\"city\":\"hidden\",\"country\":\"hidden\",\"disclosure_notice\":\"optional\",\"gender\":\"hidden\",\"goals\":\"hidden\",\"honor_code\":\"hidden\",\"language\":\"hidden\",\"level_of_education\":\"hidden\",\"mailing_address\":\"hidden\",\"terms_of_service\":\"required\",\"year_of_birth\":\"hidden\"},\"COURSES_ARE_BROWSABLE\":false,\"PREFERRED_THIRD_PARTY_AUTH_REDIRECT_URL\":\"/\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_TEXT\":\"Sign in\",\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"/auth/login/azuread-oauth2\"}';
    SET preview_config_json = '{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_THIRD_PARTY_AUTH\":true,\"RESTRICT_COURSES_API\":true,\"course_org_filter\":\"Microsoft\",\"RESTRICT_SITE_TO_LOGGED_IN_USERS\":true,\"LOGIN_EXEMPT_URLS\":[\"^faq\"],\"PREFERRED_THIRD_PARTY_AUTH_LOGIN_URL\":\"\"}';
    SET cms_config_json = '{\"ENABLE_MSA_MIGRATION\":false,\"ENABLE_AZURE_MEDIA_SERVICES_XBLOCK\":true,\"LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"LMS_ROOT_URL\":\"https://preview.bvt.oxa.microsoft.com\",\"PREVIEW_LMS_BASE\":\"preview.bvt.oxa.microsoft.com\",\"ENABLE_AUTO_LOGIN\":true}';
END IF ;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE CreateorUpdateSiteConfigs(
    IN  openedx_site_id VARCHAR(50),
    IN  openedx_config_json LONGTEXT,
    IN  courses_site_id VARCHAR(50),
    IN  courses_config_json LONGTEXT,
    IN  preview_site_id VARCHAR(50),
    IN  preview_config_json LONGTEXT,
    IN  cms_site_id VARCHAR(50),
    IN  cms_config_json LONGTEXT)

BEGIN

--
-- INSERT site configs for openedx, Update if configs already exist 
--
IF  exists (SELECT site_id FROM site_configuration_siteconfiguration WHERE site_id = openedx_site_id) THEN
    UPDATE site_configuration_siteconfiguration SET `enabled`=1,`values`= @openedx_config_json    WHERE site_id=openedx_site_id;
ELSE 
    INSERT INTO site_configuration_siteconfiguration (`enabled`, `values`, `site_id`) VALUES (1,openedx_config_json, openedx_site_id);
END IF ;

--
-- INSERT site configs for courses, Update if configs already exist
--
IF  exists (SELECT site_id FROM site_configuration_siteconfiguration WHERE site_id = courses_site_id) THEN
    UPDATE site_configuration_siteconfiguration SET `enabled`=1, `values`= @courses_config_json    WHERE site_id=courses_site_id;
ELSE 
    INSERT INTO site_configuration_siteconfiguration (`enabled`, `values`, `site_id`) VALUES (1,courses_config_json, courses_site_id);
END IF ;

--
-- INSERT site configs for preview, Update if configs already exist
--
IF  exists (SELECT site_id FROM site_configuration_siteconfiguration WHERE site_id = preview_site_id) THEN
    UPDATE site_configuration_siteconfiguration SET `enabled`=1,`values`= @preview_config_json    WHERE site_id=preview_site_id;
ELSE 
    INSERT INTO site_configuration_siteconfiguration (`enabled`, `values`, `site_id`) VALUES (1,preview_config_json, preview_site_id);
END IF ;

--
-- INSERT site configs for cms, Update if configs already exist
--
IF  exists (SELECT site_id FROM site_configuration_siteconfiguration WHERE site_id = cms_site_id) THEN
    UPDATE site_configuration_siteconfiguration SET `enabled`=1,`values`= @cms_config_json    WHERE site_id=cms_site_id;
ELSE 
    INSERT INTO site_configuration_siteconfiguration (`enabled`, `values`, `site_id`) VALUES (1,cms_config_json, cms_site_id);
END IF ;  


END $$
DELIMITER ;


CALL GetSiteNames(
  @env,
  @openedx_site,
  @courses_site,
  @preview_site,
  @cms_site
  );
CALL GetSiteIds(
  @openedx_site,
  @courses_site,
  @preview_site,
  @cms_site,
  @openedx_site_id,
  @courses_site_id,
  @preview_site_id,
  @cms_site_id
  );
CALL GetSiteconfigs(
  @env,
  @openedx_config_json,
  @courses_config_json,
  @preview_config_json,
  @cms_config_json
  );

CALL CreateorUpdateSiteConfigs(
  @openedx_site_id,
  @openedx_config_json,
  @courses_site_id,
  @courses_config_json,
  @preview_site_id,
  @preview_config_json,
  @cms_site_id,
  @cms_config_json
  );
