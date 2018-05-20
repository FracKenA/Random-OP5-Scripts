#!/bin/bash
#
# Description: Takes all groups and hides "Logger" from their user menus
#

# Get all groups and populate ninja menus
echo "---" > /etc/op5/ninja_menu.yml
for GROUP in $(grep -v "^\s" /etc/op5/auth_groups.yml | grep -v "-" | cut -d":" -f1) ; do
  echo "$GROUP:" >> /etc/op5/ninja_menu.yml
  echo "   hidden:" >> /etc/op5/ninja_menu.yml
  echo "      - \"log_messages\"" >> /etc/op5/ninja_menu.yml
done
