USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE MEDIASET_LAB;

CREATE OR REPLACE API INTEGRATION my_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-cgavazzeni')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY mediaset_lab.public.mediasetlab_repo
  API_INTEGRATION = my_git_api_integration
  ORIGIN = 'https://github.com/sfc-gh-cgavazzeni/MediasetLab.git';
