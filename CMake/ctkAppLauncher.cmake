###########################################################################
#
#  Library:   CTK
# 
#  Copyright (c) 2010  Kitware Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.commontk.org/LICENSE
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
###########################################################################

#
# See http://www.cmake.org/Wiki/CMakeMacroParseArguments
#
MACRO(ctkAppLauncherMacroParseArguments prefix arg_names option_names)
  SET(DEFAULT_ARGS)
  FOREACH(arg_name ${arg_names})
    SET(${prefix}_${arg_name})
  ENDFOREACH(arg_name)
  FOREACH(option ${option_names})
    SET(${prefix}_${option} FALSE)
  ENDFOREACH(option)

  SET(current_arg_name DEFAULT_ARGS)
  SET(current_arg_list)
  FOREACH(arg ${ARGN})
    SET(larg_names ${arg_names})
    LIST(FIND larg_names "${arg}" is_arg_name)
    IF (is_arg_name GREATER -1)
      SET(${prefix}_${current_arg_name} ${current_arg_list})
      SET(current_arg_name ${arg})
      SET(current_arg_list)
    ELSE (is_arg_name GREATER -1)
      SET(loption_names ${option_names})    
      LIST(FIND loption_names "${arg}" is_option)
      IF (is_option GREATER -1)
        SET(${prefix}_${arg} TRUE)
      ELSE (is_option GREATER -1)
        SET(current_arg_list ${current_arg_list} ${arg})
      ENDIF (is_option GREATER -1)
    ENDIF (is_arg_name GREATER -1)
  ENDFOREACH(arg)
  SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO()

#
# 
#

MACRO(ctkAppLauncherConfigure)
  ctkAppLauncherMacroParseArguments(CTKAPPLAUNCHER
    "EXECUTABLE;APPLICATION_NAME;APPLICATION_PATH;SETTINGS_TEMPLATE;DESTINATION_DIR;SPLASHSCREEN_HIDE_DELAY_MS;SPLASH_IMAGE_PATH;DEFAULT_APPLICATION_ARGUMENT;LIBRARY_PATHS_BUILD;LIBRARY_PATHS_INSTALLED;PATHS_BUILD;PATHS_INSTALLED;ENVVARS_BUILD;ENVVARS_INSTALLED;ADDITIONAL_HELP_SHORT_ARG;ADDITIONAL_HELP_LONG_ARG;ADDITIONAL_NOSPLASH_SHORT_ARG;ADDITIONAL_NOSPLASH_LONG_ARG"
    "VERBOSE_CONFIG"
    ${ARGN}
    )
  
  # If CTKAPPLAUNCHER_DIR is set, try to autodiscover the location of launcher executable and settings template file
  IF(EXISTS "${CTKAPPLAUNCHER_DIR}")
    FIND_PROGRAM(CTKAPPLAUNCHER_EXECUTABLE CTKAppLauncher PATHS ${CTKAPPLAUNCHER_DIR}/bin NO_DEFAULT_PATH)
    FIND_FILE(CTKAPPLAUNCHER_SETTINGS_TEMPLATE CTKAppLauncherSettings.ini.in PATHS ${CTKAPPLAUNCHER_DIR}/bin NO_DEFAULT_PATH)
  ENDIF()
    
  # Sanity checks - Are mandatory variable defined
  FOREACH(varname EXECUTABLE APPLICATION_NAME APPLICATION_PATH SETTINGS_TEMPLATE DESTINATION_DIR
                  LIBRARY_PATHS_BUILD)
    IF(NOT DEFINED CTKAPPLAUNCHER_${varname})
      MESSAGE(FATAL_ERROR "${varname} is mandatory")
    ENDIF()
  ENDFOREACH()
  
  # Sanity checks - Do files/directories exist ?
  FOREACH(varname EXECUTABLE APPLICATION_PATH SETTINGS_TEMPLATE DESTINATION_DIR)
    IF(NOT EXISTS ${CTKAPPLAUNCHER_${varname}})
      MESSAGE(FATAL_ERROR "${varname} [${CTKAPPLAUNCHER_${varname}}] doesn't seem to exist !")
    ENDIF()
  ENDFOREACH()
  
  # Set splash image name
  SET(CTKAPPLAUNCHER_SPLASH_IMAGE_NAME)
  IF(DEFINED CTKAPPLAUNCHER_SPLASH_IMAGE_PATH)
    IF(NOT EXISTS ${CTKAPPLAUNCHER_SPLASH_IMAGE_PATH})
      MESSAGE(FATAL_ERROR "SPLASH_IMAGE_PATH [${CTKAPPLAUNCHER_SPLASH_IMAGE_PATH}] doesn't seem to exist !")
    ENDIF()
    get_filename_component(CTKAPPLAUNCHER_SPLASH_IMAGE_NAME ${CTKAPPLAUNCHER_SPLASH_IMAGE_PATH} NAME)
  ENDIF()
  
  # Set splashscreen hide delay in ms
  IF(DEFINED CTKAPPLAUNCHER_SPLASHSCREEN_HIDE_DELAY_MS)
    IF(CTKAPPLAUNCHER_SPLASHSCREEN_HIDE_DELAY_MS LESS 0)
      MESSAGE(FATAL_ERROR "SPLASHSCREEN_HIDE_DELAY_MS [${CTKAPPLAUNCHER_SPLASHSCREEN_HIDE_DELAY_MS}] should be >= 0 !")
    ENDIF()
  ELSE()
    SET(SPLASHSCREEN_HIDE_DELAY_MS 0)
  ENDIF()

  # Informational message ... 
  SET(extra_message)
  IF(NOT ${CTKAPPLAUNCHER_SPLASH_IMAGE_NAME} STREQUAL "")
    SET(extra_message " [${CTKAPPLAUNCHER_SPLASH_IMAGE_NAME}]")
  ENDIF()
  MESSAGE(STATUS "Configuring application launcher: ${CTKAPPLAUNCHER_APPLICATION_NAME}${extra_message}")
  
  # Build type
  SET(CTKAPPLAUNCHER_BUILD_TYPE)
  IF(WIN32)
    SET(CTKAPPLAUNCHER_BUILD_TYPE ${CTKAPPLAUNCHER_BUILD_TYPE})
  ENDIF()
  
  #-----------------------------------------------------------------------------
  # Settings shared between the build tree and install tree.
  EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy_if_different 
    ${CTKAPPLAUNCHER_EXECUTABLE} ${CTKAPPLAUNCHER_DESTINATION_DIR}/${CTKAPPLAUNCHER_APPLICATION_NAME})
  
  IF(DEFINED CTKAPPLAUNCHER_SPLASH_IMAGE_PATH)
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy_if_different 
      ${CTKAPPLAUNCHER_SPLASH_IMAGE_PATH} ${CTKAPPLAUNCHER_DESTINATION_DIR}/${CTKAPPLAUNCHER_SPLASH_IMAGE_NAME})
  ENDIF()
  
  FILE(RELATIVE_PATH CTKAPPLAUNCHER_APPLICATION_PATH_CONFIG ${CTKAPPLAUNCHER_DESTINATION_DIR} ${CTKAPPLAUNCHER_APPLICATION_PATH})

  #-----------------------------------------------------------------------------
  # Settings specific to the build tree.
    
  SET(idx 1)
  SET(CTKAPPLAUNCHER_LIBRARY_PATHS)
  LIST(LENGTH CTKAPPLAUNCHER_LIBRARY_PATHS_BUILD path_count)
  FOREACH(path ${CTKAPPLAUNCHER_LIBRARY_PATHS_BUILD})
    SET(CTKAPPLAUNCHER_LIBRARY_PATHS "${CTKAPPLAUNCHER_LIBRARY_PATHS}${idx}\\path=${path}\n")
    MATH(EXPR idx "${idx} + 1")
  ENDFOREACH()
  SET(CTKAPPLAUNCHER_LIBRARY_PATHS "${CTKAPPLAUNCHER_LIBRARY_PATHS}size=${path_count}")
  
  SET(idx 1)
  SET(CTKAPPLAUNCHER_PATHS)
  LIST(LENGTH CTKAPPLAUNCHER_PATHS_BUILD path_count)
  FOREACH(path ${CTKAPPLAUNCHER_PATHS_BUILD})
    SET(CTKAPPLAUNCHER_PATHS "${CTKAPPLAUNCHER_PATHS}${idx}\\path=${path}\n")
    MATH(EXPR idx "${idx} + 1")
  ENDFOREACH()
  SET(CTKAPPLAUNCHER_PATHS "${CTKAPPLAUNCHER_PATHS}size=${path_count}")
  
  SET(CTKAPPLAUNCHER_ENVVARS)
  FOREACH(envvar ${CTKAPPLAUNCHER_ENVVARS_BUILD})
    SET(CTKAPPLAUNCHER_ENVVARS "${CTKAPPLAUNCHER_ENVVARS}${envvar}\n")
  ENDFOREACH()
  
  CONFIGURE_FILE(
    ${CTKAPPLAUNCHER_SETTINGS_TEMPLATE}
    ${CTKAPPLAUNCHER_DESTINATION_DIR}/${CTKAPPLAUNCHER_APPLICATION_NAME}LauncherSettings.ini
    @ONLY
    )
  
  #-----------------------------------------------------------------------------
  # Settings specific to the install tree.
  
  SET(idx 1)
  SET(CTKAPPLAUNCHER_LIBRARY_PATHS)
  LIST(LENGTH CTKAPPLAUNCHER_LIBRARY_PATHS_INSTALLED path_count)
  FOREACH(path ${CTKAPPLAUNCHER_LIBRARY_PATHS_INSTALLED})
    SET(CTKAPPLAUNCHER_LIBRARY_PATHS "${CTKAPPLAUNCHER_LIBRARY_PATHS}${idx}\\path=${path}\n")
    MATH(EXPR idx "${idx} + 1")
  ENDFOREACH()
  SET(CTKAPPLAUNCHER_LIBRARY_PATHS "${CTKAPPLAUNCHER_LIBRARY_PATHS}size=${path_count}")
  
  SET(idx 1)
  SET(CTKAPPLAUNCHER_PATHS)
  LIST(LENGTH CTKAPPLAUNCHER_PATHS_INSTALLED path_count)
  FOREACH(path ${CTKAPPLAUNCHER_PATHS_INSTALLED})
    SET(CTKAPPLAUNCHER_PATHS "${CTKAPPLAUNCHER_PATHS}${idx}\\path=${path}\n")
    MATH(EXPR idx "${idx} + 1")
  ENDFOREACH()
  SET(CTKAPPLAUNCHER_PATHS "${CTKAPPLAUNCHER_PATHS}size=${path_count}")
  
  SET(CTKAPPLAUNCHER_ENVVARS)
  FOREACH(envvar ${CTKAPPLAUNCHER_ENVVARS_INSTALLED})
    SET(CTKAPPLAUNCHER_ENVVARS "${CTKAPPLAUNCHER_ENVVARS}${envvar}\n")
  ENDFOREACH()
  
  CONFIGURE_FILE(
    ${CTKAPPLAUNCHER_SETTINGS_TEMPLATE}
    ${CTKAPPLAUNCHER_DESTINATION_DIR}/${CTKAPPLAUNCHER_APPLICATION_NAME}LauncherSettingsToInstall.ini
    @ONLY
    )
  
ENDMACRO()
