FasdUAS 1.101.10   ��   ��    k             l      ��  ��   ��
 * This is an example apple script which demonstrates how you can update the location of 
 * your device via apple script. The script is intended to be run with LocationSimulator running
 * as daemon. You can start LocationSimulator as daemon by launching it via terminal 
 * with the '--no-ui' flag.
 *
 * You can configure the speed, the device and the GPX file at the start of the run method.
 * The script automatically interpolates between the coordinates based on the speed value.
 *
      � 	 	� 
   *   T h i s   i s   a n   e x a m p l e   a p p l e   s c r i p t   w h i c h   d e m o n s t r a t e s   h o w   y o u   c a n   u p d a t e   t h e   l o c a t i o n   o f   
   *   y o u r   d e v i c e   v i a   a p p l e   s c r i p t .   T h e   s c r i p t   i s   i n t e n d e d   t o   b e   r u n   w i t h   L o c a t i o n S i m u l a t o r   r u n n i n g 
   *   a s   d a e m o n .   Y o u   c a n   s t a r t   L o c a t i o n S i m u l a t o r   a s   d a e m o n   b y   l a u n c h i n g   i t   v i a   t e r m i n a l   
   *   w i t h   t h e   ' - - n o - u i '   f l a g . 
   * 
   *   Y o u   c a n   c o n f i g u r e   t h e   s p e e d ,   t h e   d e v i c e   a n d   t h e   G P X   f i l e   a t   t h e   s t a r t   o f   t h e   r u n   m e t h o d . 
   *   T h e   s c r i p t   a u t o m a t i c a l l y   i n t e r p o l a t e s   b e t w e e n   t h e   c o o r d i n a t e s   b a s e d   o n   t h e   s p e e d   v a l u e . 
   * 
     
  
 l     ��������  ��  ��        p         ������ 	0 speed  ��        p         ������ 0 	lastcoord 	lastCoord��        l     ��������  ��  ��        i         I     ������
�� .aevtoappnull  �   � ****��  ��    k    �       l     ��  ��    + % Speed in m/s which is approx 15 km/h     �   J   S p e e d   i n   m / s   w h i c h   i s   a p p r o x   1 5   k m / h      r        !   m      " " @�I�^ ! o      ���� 	0 speed     # $ # l   �� % &��   %   Name of the device     & � ' ' (   N a m e   o f   t h e   d e v i c e   $  ( ) ( r     * + * m     , , � - -  D a v i d s   i P h o n e + o      ���� 0 
devicename 
deviceName )  . / . l   �� 0 1��   0   Path to the GPX file    1 � 2 2 *   P a t h   t o   t h e   G P X   f i l e /  3 4 3 r     5 6 5 m    	 7 7 � 8 8 < / U s e r s / D a v i d / D e s k t o p / t e s t 2 . g p x 6 o      ���� 0 filename fileName 4  9 : 9 l   ��������  ��  ��   :  ; < ; r     = > = m    ��
�� 
msng > o      ���� 0 	lastcoord 	lastCoord <  ? @ ? l   ��������  ��  ��   @  A�� A O   � B C B k   � D D  E F E r    # G H G 6   ! I J I 4   �� K
�� 
LSDE K m    ����  J C      L M L 1    ��
�� 
pnam M o    ���� 0 
devicename 
deviceName H o      ���� 0 mydevice myDevice F  N O N r   $ ) P Q P n   $ ' R S R 1   % '��
�� 
pnam S o   $ %���� 0 mydevice myDevice Q o      ���� 0 
devicename 
deviceName O  T U T I  * 3�� V��
�� .ascrcmnt****      � **** V l  * / W���� W b   * / X Y X b   * - Z [ Z m   * + \ \ � ] ]  P a i r   d e v i c e   [ o   + ,���� 0 
devicename 
deviceName Y m   - . ^ ^ � _ _  . . .��  ��  ��   U  ` a ` O  4 > b c b I  8 =������
�� .LSpairdenull���     LSDE��  ��   c o   4 5���� 0 mydevice myDevice a  d e d I  ? H�� f��
�� .ascrcmnt****      � **** f l  ? D g���� g b   ? D h i h o   ? @���� 0 
devicename 
deviceName i m   @ C j j � k k    p a i r e d��  ��  ��   e  l m l l  I I��������  ��  ��   m  n o n l  I I�� p q��   p [ U somehow we always need an alias to access the file... seems like an apple script bug    q � r r �   s o m e h o w   w e   a l w a y s   n e e d   a n   a l i a s   t o   a c c e s s   t h e   f i l e . . .   s e e m s   l i k e   a n   a p p l e   s c r i p t   b u g o  s t s r   I R u v u n   I N w x w 1   J N��
�� 
psxp x o   I J���� 0 filename fileName v o      ���� 0 mypath myPath t  y z y r   S c { | { c   S _ } ~ } l  S [ ����  4   S [�� �
�� 
psxf � o   W Z���� 0 mypath myPath��  ��   ~ m   [ ^��
�� 
alis | o      ���� 0 myalias myAlias z  � � � l  d d��������  ��  ��   �  � � � r   d s � � � I  d o���� �
�� .LSldgpxfnull��� ��� null��   � �� ���
�� 
Lsfl � o   h k���� 0 myalias myAlias��   � o      ���� 0 gpxfile gpxFile �  � � � l  t t�� � ���   � ) #set myFilePath to (path of gpxFile)    � � � � F s e t   m y F i l e P a t h   t o   ( p a t h   o f   g p x F i l e ) �  � � � l  t t�� � ���   �  log (myFilePath)    � � � �   l o g   ( m y F i l e P a t h ) �  � � � l  t t��������  ��  ��   �  � � � l  t t�� � ���   �  
 waypoints    � � � �    w a y p o i n t s �  � � � I  t {�� ���
�� .ascrcmnt****      � **** � l  t w ����� � m   t w � � � � �   U s e   w a y p o i n t s . . .��  ��  ��   �  � � � r   | � � � � l  | � ����� � n   | � � � � 2   ���
�� 
LSWP � o   | ���� 0 gpxfile gpxFile��  ��   � o      ���� 0 mywaypoints myWaypoints �  � � � X   � � ��� � � n  � � � � � I   � ��� ����� &0 "update_location_with_interpolation   �  � � � o   � ����� 0 mydevice myDevice �  ��� � o   � ����� 0 wp  ��  ��   �  f   � ��� 0 wp   � o   � ����� 0 mywaypoints myWaypoints �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   �   tracks    � � � �    t r a c k s �  � � � I  � ��� ���
�� .ascrcmnt****      � **** � l  � � ����� � m   � � � � � � �  U s e   t r a c k s . . .��  ��  ��   �  � � � r   � � � � � l  � � ����� � n   � � � � � 2  � ���
�� 
LSTR � o   � ����� 0 gpxfile gpxFile��  ��   � o      ���� 0 mytracks myTracks �  � � � X   � ��� � � X   � ��� � � X   � ��� � � n  � � � I  �� ����� &0 "update_location_with_interpolation   �  � � � o  ���� 0 mydevice myDevice �  ��� � o  ���� 0 pt  ��  ��   �  f  �� 0 pt   � l  � � ����� � n   � � � � � 2  � ���
�� 
LSTP � o   � ����� 0 seg  ��  ��  �� 0 seg   � l  � � ����� � n   � � � � � 2  � ���
�� 
LSSG � o   � ����� 0 tr  ��  ��  �� 0 tr   � o   � ����� 0 mytracks myTracks �  � � � l �������  ��  �   �  � � � l �~ � ��~   �   routes    � � � �    r o u t e s �  � � � I #�} ��|
�} .ascrcmnt****      � **** � l  ��{�z � m   � � � � �  U s e   r o u t e s . . .�{  �z  �|   �  � � � r  $/ � � � l $+ ��y�x � n  $+ � � � 2 '+�w
�w 
LSRO � o  $'�v�v 0 gpxfile gpxFile�y  �x   � o      �u�u 0 myroutes myRoutes �  � � � X  0o ��t � � X  Fj ��s � � n ^e � � � I  _e�r ��q�r &0 "update_location_with_interpolation   �  � � � o  _`�p�p 0 mydevice myDevice �  ��o � o  `a�n�n 0 pt  �o  �q   �  f  ^_�s 0 pt   � l IN ��m�l � n IN � � � 2 JN�k
�k 
LSRP � o  IJ�j�j 0 rt  �m  �l  �t 0 rt   � o  36�i�i 0 myroutes myRoutes �  � � � l pp�h�g�f�h  �g  �f   �  � � � l pp�e �e     	 cleanup     �    c l e a n u p   �  I pw�d�c
�d .ascrcmnt****      � **** l ps�b�a m  ps �  C l e a n u p . . .�b  �a  �c   	
	 O x� I ~��`�_�^
�` .LSclogpxnull���     LSGX�_  �^   o  x{�]�] 0 gpxfile gpxFile
 �\ I ���[�Z
�[ .ascrcmnt****      � **** l ���Y�X m  �� �  F i n i s h e d .�Y  �X  �Z  �\   C m    z                                                                                      @ alis      Macintosh HD               �H&BD ����LocationSimulator.app                                          �����*��        ����  
 cu             Debug   �/:Users:David:Library:Developer:Xcode:DerivedData:LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx:Build:Products:Debug:LocationSimulator.app/  ,  L o c a t i o n S i m u l a t o r . a p p    M a c i n t o s h   H D  �Users/David/Library/Developer/Xcode/DerivedData/LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx/Build/Products/Debug/LocationSimulator.app   /    ��  ��     l     �W�V�U�W  �V  �U    i     I      �T�S�T 0 heading    o      �R�R 
0 coord1   �Q o      �P�P 
0 coord2  �Q  �S   k     �  l     �O !�O      Convert to radians   ! �"" &   C o n v e r t   t o   r a d i a n s #$# r     
%&% l    '�N�M' ^     ()( ]     *+* l    ,�L�K, n     -.- 4   �J/
�J 
cobj/ m    �I�I . o     �H�H 
0 coord1  �L  �K  + 1    �G
�G 
pi  ) m    �F�F ��N  �M  & o      �E�E 0 lat1  $ 010 r    232 l   4�D�C4 ^    565 ]    787 l   9�B�A9 n    :;: 4   �@<
�@ 
cobj< m    �?�? ; o    �>�> 
0 coord1  �B  �A  8 1    �=
�= 
pi  6 m    �<�< ��D  �C  3 o      �;�; 0 lon1  1 =>= l   �:�9�8�:  �9  �8  > ?@? r     ABA l   C�7�6C ^    DED ]    FGF l   H�5�4H n    IJI 4   �3K
�3 
cobjK m    �2�2 J o    �1�1 
0 coord2  �5  �4  G 1    �0
�0 
pi  E m    �/�/ ��7  �6  B o      �.�. 0 lat2  @ LML r   ! +NON l  ! )P�-�,P ^   ! )QRQ ]   ! 'STS l  ! %U�+�*U n   ! %VWV 4  " %�)X
�) 
cobjX m   # $�(�( W o   ! "�'�' 
0 coord2  �+  �*  T 1   % &�&
�& 
pi  R m   ' (�%�% ��-  �,  O o      �$�$ 0 lon2  M YZY l  , ,�#�"�!�#  �"  �!  Z [\[ O   , �]^] k   0 �__ `a` r   0 5bcb \   0 3ded o   0 1� �  0 lon2  e o   1 2�� 0 lon1  c o      �� 0 dlon dLona fgf r   6 Ghih ]   6 Ejkj l  6 =l��l I  6 =��m
� .LSsinfunnull��� ��� null�  m �n�
� 
Lssin o   8 9�� 0 dlon dLon�  �  �  k l  = Do��o I  = D��p
� .LScosfunnull��� ��� null�  p �q�
� 
Lscoq o   ? @�� 0 lat2  �  �  �  i o      �� 0 yval yValg rsr r   H qtut \   H ovwv ]   H Wxyx l  H Oz��z I  H O��{
� .LScosfunnull��� ��� null�  { �
|�	
�
 
Lsco| o   J K�� 0 lat1  �	  �  �  y l  O V}��} I  O V��~
� .LSsinfunnull��� ��� null�  ~ ��
� 
Lssi o   Q R�� 0 lat2  �  �  �  w ]   W n��� ]   W f��� l  W ^�� ��� I  W ^�����
�� .LSsinfunnull��� ��� null��  � �����
�� 
Lssi� o   Y Z���� 0 lat1  ��  �   ��  � l  ^ e������ I  ^ e�����
�� .LScosfunnull��� ��� null��  � �����
�� 
Lsco� o   ` a���� 0 lat2  ��  ��  ��  � l  f m������ I  f m�����
�� .LScosfunnull��� ��� null��  � �����
�� 
Lsco� o   h i���� 0 dlon dLon��  ��  ��  u o      ���� 0 xval xVals ���� r   r ���� ^   r ��� ]   r }��� l  r {������ I  r {�����
�� .LSatafunnull��� ��� null��  � ����
�� 
Lsyp� o   t u���� 0 yval yVal� �����
�� 
Lsxp� o   v w���� 0 xval xVal��  ��  ��  � m   { |���� �� 1   } ~��
�� 
pi  � o      ����  0 headingdegrees headingDegrees��  ^ m   , -��z                                                                                      @ alis      Macintosh HD               �H&BD ����LocationSimulator.app                                          �����*��        ����  
 cu             Debug   �/:Users:David:Library:Developer:Xcode:DerivedData:LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx:Build:Products:Debug:LocationSimulator.app/  ,  L o c a t i o n S i m u l a t o r . a p p    M a c i n t o s h   H D  �Users/David/Library/Developer/Xcode/DerivedData/LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx/Build/Products/Debug/LocationSimulator.app   /    ��  \ ��� l  � ���������  ��  ��  � ���� Z   � ������� @   � ���� o   � �����  0 headingdegrees headingDegrees� m   � �����  � L   � ��� o   � �����  0 headingdegrees headingDegrees��  � L   � ��� [   � ���� o   � �����  0 headingdegrees headingDegrees� m   � �����h��   ��� l     ��������  ��  ��  � ��� i    ��� I      ������� 0 next  � ��� o      ���� 	0 coord  � ��� o      ���� 0 heading  � ���� o      ���� 0 dis  ��  ��  � k     |�� ��� r     ��� l    ������ n     ��� 4   ���
�� 
cobj� m    ���� � o     ���� 	0 coord  ��  ��  � o      ���� 0 lat  � ��� r    ��� l   ������ n    ��� 4   ���
�� 
cobj� m   	 
���� � o    ���� 	0 coord  ��  ��  � o      ���� 0 lon  � ��� l   ��������  ��  ��  � ��� r    ��� ]    ��� ]    ��� m    ���� � 1    ��
�� 
pi  � m    �� AXM�    � o      ���� 0 earthcircle earthCircle� ��� l   ��������  ��  ��  � ��� O    v��� k    u�� ��� r    )��� ]    '��� o    ���� 0 dis  � l   &������ I   &�����
�� .LScosfunnull��� ��� null��  � �����
�� 
Lsco� l   "������ ^    "��� ]     ��� o    ���� 0 heading  � 1    ��
�� 
pi  � m     !���� ���  ��  ��  ��  ��  � o      ���� 0 latdistance latDistance� ��� r   * /��� ^   * -��� m   * +����h� o   + ,���� 0 earthcircle earthCircle� o      ���� 0 latpermeter latPerMeter� ��� r   0 5��� ]   0 3��� o   0 1���� 0 latdistance latDistance� o   1 2���� 0 latpermeter latPerMeter� o      ���� 0 latdelta latDelta� ��� r   6 ;��� [   6 9��� o   6 7���� 0 lat  � o   7 8���� 0 latdelta latDelta� o      ���� 0 newlat newLat� ��� l  < <��������  ��  ��  � ��� r   < K��� ]   < I��� l  < =������ o   < =���� 0 dis  ��  ��  � l  = H������ I  = H�����
�� .LSsinfunnull��� ��� null��  � �� ��
�� 
Lssi  l  ? D���� ^   ? D ]   ? B o   ? @���� 0 heading   1   @ A��
�� 
pi   m   B C���� ���  ��  ��  ��  ��  � o      ���� 0 lngdistance lngDistance�  r   L [	 ]   L Y

 m   L M AXM�     l  M X���� I  M X����
�� .LScosfunnull��� ��� null��   ����
�� 
Lsco l  O T���� ^   O T ]   O R o   O P���� 0 newlat newLat 1   P Q��
�� 
pi   m   R S���� ���  ��  ��  ��  ��  	 o      ���� $0 earthradiusatlng earthRadiusAtLng  r   \ c ]   \ a ]   \ _ m   \ ]����  1   ] ^��
�� 
pi   o   _ `�� $0 earthradiusatlng earthRadiusAtLng o      �~�~ $0 earthcircleatlng earthCircleAtLng  r   d i  ^   d g!"! m   d e�}�}h" o   e f�|�| $0 earthcircleatlng earthCircleAtLng  o      �{�{ 0 lngpermeter lngPerMeter #$# r   j o%&% ]   j m'(' o   j k�z�z 0 lngdistance lngDistance( o   k l�y�y 0 lngpermeter lngPerMeter& o      �x�x 0 lngdelta lngDelta$ )�w) r   p u*+* [   p s,-, o   p q�v�v 0 lon  - o   q r�u�u 0 lngdelta lngDelta+ o      �t�t 0 newlng newLng�w  � m    ..z                                                                                      @ alis      Macintosh HD               �H&BD ����LocationSimulator.app                                          �����*��        ����  
 cu             Debug   �/:Users:David:Library:Developer:Xcode:DerivedData:LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx:Build:Products:Debug:LocationSimulator.app/  ,  L o c a t i o n S i m u l a t o r . a p p    M a c i n t o s h   H D  �Users/David/Library/Developer/Xcode/DerivedData/LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx/Build/Products/Debug/LocationSimulator.app   /    ��  � /0/ l  w w�s�r�q�s  �r  �q  0 1�p1 L   w |22 J   w {33 454 o   w x�o�o 0 newlat newLat5 6�n6 o   x y�m�m 0 newlng newLng�n  �p  � 787 l     �l�k�j�l  �k  �j  8 9�i9 i    :;: I      �h<�g�h &0 "update_location_with_interpolation  < =>= o      �f�f 0 mydevice myDevice> ?�e? o      �d�d 0 pt  �e  �g  ; O     �@A@ k    �BB CDC r    	EFE n    GHG 1    �c
�c 
LScnH o    �b�b 0 pt  F o      �a�a 	0 coord  D IJI l  
 
�`�_�^�`  �_  �^  J KLK l  
 
�]MN�]  M C = Interpolate from the current location to the next coordinate   N �OO z   I n t e r p o l a t e   f r o m   t h e   c u r r e n t   l o c a t i o n   t o   t h e   n e x t   c o o r d i n a t eL PQP r   
 RSR m   
 �\�\  S o      �[�[ 0 dis  Q TUT r    VWV m    �Z
�Z boovtrueW o      �Y�Y 0 con  U X�XX V    �YZY k    �[[ \]\ Z    Z^_�W`^ =   aba o    �V�V 0 	lastcoord 	lastCoordb m    �U
�U 
msng_ k    %cc ded r    !fgf o    �T�T 	0 coord  g o      �S�S 0 nextlocation nextLocatione h�Rh r   " %iji m   " #�Q
�Q boovfalsj o      �P�P 0 con  �R  �W  ` k   ( Zkk lml l  ( (�Ono�O  n - ' Calculate the next location we move to   o �pp N   C a l c u l a t e   t h e   n e x t   l o c a t i o n   w e   m o v e   t om qrq r   ( 1sts n  ( /uvu I   ) /�Nw�M�N 0 heading  w xyx o   ) *�L�L 0 	lastcoord 	lastCoordy z�Kz o   * +�J�J 	0 coord  �K  �M  v  f   ( )t o      �I�I 0 	direction  r {|{ r   2 <}~} n  2 :� I   3 :�H��G�H 0 next  � ��� o   3 4�F�F 0 	lastcoord 	lastCoord� ��� o   4 5�E�E 0 	direction  � ��D� o   5 6�C�C 	0 speed  �D  �G  �  f   2 3~ o      �B�B 0 nextlocation nextLocation| ��� r   = H��� I  = F�A�@�
�A .LSheadbenull��� ��� null�@  � �?��
�? 
Lspo� o   ? @�>�> 0 nextlocation nextLocation� �=��<
�= 
Lsat� o   A B�;�; 	0 coord  �<  � o      �:�: 0 dis  � ��9� Z   I Z���8�7� A   I L��� o   I J�6�6 0 dis  � o   J K�5�5 	0 speed  � k   O V�� ��� r   O R��� o   O P�4�4 	0 coord  � o      �3�3 0 nextlocation nextLocation� ��2� r   S V��� m   S T�1
�1 boovfals� o      �0�0 0 con  �2  �8  �7  �9  ] ��� l  [ [�/�.�-�/  �.  �-  � ��� r   [ a��� n   [ _��� 4  \ _�,�
�, 
cobj� m   ] ^�+�+ � o   [ \�*�* 0 nextlocation nextLocation� o      �)�) 0 lat  � ��� r   b h��� n   b f��� 4  c f�(�
�( 
cobj� m   d e�'�' � o   b c�&�& 0 nextlocation nextLocation� o      �%�% 0 lng  � ��� I  i t�$��#
�$ .ascrcmnt****      � ****� l  i p��"�!� b   i p��� b   i n��� b   i l��� m   i j�� ��� 0 U p d a t e   l o c a t i o n   t o   l a t :  � o   j k� �  0 lat  � m   l m�� ���    l o n g :  � o   n o�� 0 lng  �"  �!  �#  � ��� O  u ���� I  y ����
� .LSsetlocnull���     LSDE�  � ���
� 
Lsla� o   { |�� 0 lat  � ���
� 
Lslo� o    ��� 0 lng  �  � o   u v�� 0 mydevice myDevice� ��� r   � ���� o   � ��� 0 nextlocation nextLocation� o      �� 0 	lastcoord 	lastCoord�  Z o    �� 0 con  �X  A m     ��z                                                                                      @ alis      Macintosh HD               �H&BD ����LocationSimulator.app                                          �����*��        ����  
 cu             Debug   �/:Users:David:Library:Developer:Xcode:DerivedData:LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx:Build:Products:Debug:LocationSimulator.app/  ,  L o c a t i o n S i m u l a t o r . a p p    M a c i n t o s h   H D  �Users/David/Library/Developer/Xcode/DerivedData/LocationSimulator-depewdcvscyvkvalvkqqdhtndlpx/Build/Products/Debug/LocationSimulator.app   /    ��  �i       �������  � ����
� .aevtoappnull  �   � ****� 0 heading  � 0 next  � &0 "update_location_with_interpolation  � � �����

� .aevtoappnull  �   � ****�  �  � �	�����	 0 wp  � 0 tr  � 0 seg  � 0 pt  � 0 rt  � - "� ,� 7��� ������� \ ^���� j���������������� ������������� ��������� ���������� 	0 speed  � 0 
devicename 
deviceName� 0 filename fileName
� 
msng�  0 	lastcoord 	lastCoord
�� 
LSDE�  
�� 
pnam�� 0 mydevice myDevice
�� .ascrcmnt****      � ****
�� .LSpairdenull���     LSDE
�� 
psxp�� 0 mypath myPath
�� 
psxf
�� 
alis�� 0 myalias myAlias
�� 
Lsfl
�� .LSldgpxfnull��� ��� null�� 0 gpxfile gpxFile
�� 
LSWP�� 0 mywaypoints myWaypoints
�� 
kocl
�� 
cobj
�� .corecnte****       ****�� &0 "update_location_with_interpolation  
�� 
LSTR�� 0 mytracks myTracks
�� 
LSSG
�� 
LSTP
�� 
LSRO�� 0 myroutes myRoutes
�� 
LSRP
�� .LSclogpxnull���     LSGX�
��E�O�E�O�E�O�E�O�z*�k/�[�,\Z�>1E�O��,E�O��%�%j O� *j UO�a %j O�a ,E` O*a _ /a &E` O*a _ l E` Oa j O_ a -E` O !_ [a a l kh  )̠l+  [OY��Oa !j O_ a "-E` #O [_ #[a a l kh  @�a $-[a a l kh  #�a %-[a a l kh )̣l+  [OY��[OY��[OY��Oa &j O_ a '-E` (O >_ ([a a l kh  #�a )-[a a l kh )̣l+  [OY��[OY��Oa *j O_  *j +UOa ,j U� ������������ 0 heading  �� ����� �  ������ 
0 coord1  �� 
0 coord2  ��  � 
���������������������� 
0 coord1  �� 
0 coord2  �� 0 lat1  �� 0 lon1  �� 0 lat2  �� 0 lon2  �� 0 dlon dLon�� 0 yval yVal�� 0 xval xVal��  0 headingdegrees headingDegrees� �������������������������
�� 
cobj
�� 
pi  �� �
�� 
Lssi
�� .LSsinfunnull��� ��� null
�� 
Lsco
�� .LScosfunnull��� ��� null
�� 
Lsyp
�� 
Lsxp�� 
�� .LSatafunnull��� ��� null��h�� ���k/� �!E�O��l/� �!E�O��k/� �!E�O��l/� �!E�O� S��E�O*�l *�l  E�O*�l *�l  *�l *�l  *�l  E�O*��� � �!E�UO�j �Y ��� ������������� 0 next  �� ����� �  �������� 	0 coord  �� 0 heading  �� 0 dis  ��  � ���������������������������������� 	0 coord  �� 0 heading  �� 0 dis  �� 0 lat  �� 0 lon  �� 0 earthcircle earthCircle�� 0 latdistance latDistance�� 0 latpermeter latPerMeter�� 0 latdelta latDelta�� 0 newlat newLat�� 0 lngdistance lngDistance�� $0 earthradiusatlng earthRadiusAtLng�� $0 earthcircleatlng earthCircleAtLng�� 0 lngpermeter lngPerMeter�� 0 lngdelta lngDelta�� 0 newlng newLng� 
�����.������������
�� 
cobj
�� 
pi  
�� 
Lsco�� �
�� .LScosfunnull��� ��� null��h
�� 
Lssi
�� .LSsinfunnull��� ��� null�� }��k/E�O��l/E�Ol� � E�O� ]�*�� �!l  E�O�!E�O�� E�O��E�O�*�� �!l 	 E�O�*�� �!l  E�Ol� � E�O�!E�O�� E�O��E�UO��lv� ��;���������� &0 "update_location_with_interpolation  �� ����� �  ������ 0 mydevice myDevice�� 0 pt  ��  � 	�������������������� 0 mydevice myDevice�� 0 pt  �� 	0 coord  �� 0 dis  �� 0 con  �� 0 nextlocation nextLocation�� 0 	direction  �� 0 lat  �� 0 lng  � ���������������������������������
�� 
LScn�� 0 	lastcoord 	lastCoord
�� 
msng�� 0 heading  �� 	0 speed  �� 0 next  
�� 
Lspo
�� 
Lsat�� 
�� .LSheadbenull��� ��� null
�� 
cobj
�� .ascrcmnt****      � ****
�� 
Lsla
�� 
Lslo
�� .LSsetlocnull���     LSDE�� �� ���,E�OjE�OeE�O {h���  �E�OfE�Y 4)¢l+ E�O)¦�m+ E�O*��� 
E�O�� �E�OfE�Y hO��k/E�O��l/E�O�%�%�%j O� *�a �� UO�E�[OY��Uascr  ��ޭ