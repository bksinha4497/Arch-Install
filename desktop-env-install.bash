#!/bin/bash

gnome_install() {
  echo "Installing Gnome"
  sudo pacman -Sy --noconfirm xorg gdm gnome gnome-extra gnome-tweaks firefox vlc
  sudo systemctl enable gdm
  echo "Installation complete , you can reboot now"
}

kde_install() {
  echo "Installing KDE"
  sudo pacman -Sy --noconfirm xorg sddm plasma kde-applications firefox vlc
  sudo systemctl enable sddm
  echo "Installation compelte , you can reboot now"
}

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
  clear
}

incorrect_selection() {
  echo "Incorrect selection! Try again."
}

until [ "$selection" = "0" ]; do
  clear
  echo ""
  echo "    	1  -  Install Gnome"
  echo "    	2  -  Install Kde"
  echo "        3  -  Reboot"
  echo "    	0  -  Exit"
  echo ""
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; gnome_install ; press_enter ;;
    2 ) clear ; kde_install ; press_enter ;;
    3 ) clear ; reboot;;
    0 ) clear ; exit ;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done
