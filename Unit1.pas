unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  OpenGl, ExtCtrls, StdCtrls, Series, TeEngine, TeeProcs, Chart, Spin, Buttons;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Timer2: TTimer;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Timer3: TTimer;
    btn1: TButton;
    btn2: TButton;
    cht1: TChart;
    lnsrsSeries1: TLineSeries;
    lnsrsSeries2: TLineSeries;
    se1: TSpinEdit;
    se2: TSpinEdit;
    se3: TSpinEdit;
    btn3: TBitBtn;
    rb1: TRadioButton;
    rb2: TRadioButton;
    rb3: TRadioButton;
    grp1: TGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure se1Change(Sender: TObject);
    procedure se2Change(Sender: TObject);
    procedure se3Change(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);

  private
    myDC: HDC;
    myRC: HGLRC;
    myPalette: HPALETTE;
    procedure SetupPixelFormat;
  public
    { Public declarations }
  end;

const
  mat_specular: array[0..3] of GLfloat = (8.0, 8.0, 1.0, 0.0);
  mat_shininess: GLfloat = 40.0;
  light_position: array[0..3] of GLfloat = (120.6, 14.0, 41.0, 10.7);
  f0 = 1.0;
  f1 = 0.5;
  f2 = 0.5;
  f3 = 0.5;

var
  Form1: TForm1;
  rotation_angle, rotation_angle1, rotation_angle2, rotation_angle3: real;
  x_pos, y_pos, z_pos: real;
  circle_point: integer;
  angle: real;
  sphere, cylinder, disk, partial_disk: GLUquadricObj;
  time: extended;
  fix_x, upper_limb, two_upper, cyl: boolean;
  theta_dot_dot, theta_dot, theta, phi_dot_dot, phi_dot, phi: real;
  torque, torque1, m, l, g, moment_inertia: real;
  k1, k2, k3, k4, dt, k11, k21, k31, k41: real;
  roll, pitch, yaw: real;

implementation

{$R *.dfm}

procedure single_pend_equ(const theta, theta_dot, phi, phi_dot: real);
var
  numerator_theta, denominator_theta: real;
  numerator_phi, denominator_phi: real;
begin
  numerator_theta := torque + (m * sqr(l) / 8) * sqr(phi_dot) * sin(theta) * cos(theta) - (m * g * l / 2) * sin(theta);
  denominator_theta := (m * sqr(l) / 4) + moment_inertia;
  theta_dot_dot := numerator_theta / denominator_theta;

  numerator_phi := torque1 - (m * sqr(l) / 4) * phi_dot * theta_dot * sin(theta) * cos(theta);
  denominator_phi := m * sqr(l) / 8;
  phi_dot_dot := numerator_phi / denominator_phi;
end;

procedure rungekutta_single(thetab, theta_dotb, phib, phi_dotb: real);
begin
  single_pend_equ(thetab, theta_dotb, phib, phi_dotb);
  k1 := 0.5 * dt * theta_dot_dot;
  k11 := 0.5 * dt * phi_dot_dot;

  single_pend_equ(thetab + 0.5 * dt * (theta_dotb + 0.5 * k1), theta_dotb + k1, phib + 0.5 * dt * (phi_dotb + 0.5 * k11), phi_dotb + k11);
  k2 := 0.5 * dt * theta_dot_dot;
  k21 := 0.5 * dt * phi_dot_dot;

  single_pend_equ(thetab + 0.5 * dt * (theta_dotb + 0.5 * k1), theta_dotb + k2, phib + 0.5 * dt * (phi_dotb + 0.5 * k11), phi_dotb + k21);
  k3 := 0.5 * dt * theta_dot_dot;
  k31 := 0.5 * dt * phi_dot_dot;

  single_pend_equ(thetab + dt * (theta_dotb + k3), theta_dotb + 2 * k3, phib + dt * (phi_dotb + k31), phi_dotb + 2 * k31);
  k4 := 0.5 * dt * theta_dot_dot;
  k41 := 0.5 * dt * phi_dot_dot;

  theta := theta + dt * (theta_dot + 1 / 3 * (k1 + k2 + k3));
  theta_dot := theta_dot + 1 / 3 * (k1 + 2 * k2 + 2 * k3 + k4);

  phi := phi + dt * (phi_dot + 1 / 3 * (k11 + k21 + k31));
  phi_dot := phi_dot + 1 / 3 * (k11 + 2 * k21 + 2 * k31 + k41);
end;

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

procedure TForm1.SetupPixelFormat;
var
  hHeap: THandle;
  nColors, i: Integer;
  lpPalette: PLogPalette;
  byRedMask, byGreenMask, byBlueMask: Byte;
  nPixelFormat: Integer;
  pfd: TPixelFormatDescriptor;
begin
  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
  begin
    nSize := sizeof(pfd);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 32;
    cDepthBits := 32;
    iLayerType := PFD_MAIN_PLANE;
  end;
  nPixelFormat := ChoosePixelFormat(myDC, @pfd);
  SetPixelFormat(myDC, nPixelFormat, @pfd);

  DescribePixelFormat(myDC, nPixelFormat, sizeof(TPixelFormatDescriptor), pfd);
  if ((pfd.dwFlags and PFD_NEED_PALETTE) <> 0) then
  begin
    nColors := 1 shl pfd.cColorBits;
    hHeap := GetProcessHeap;
    lpPalette := HeapAlloc(hHeap, 0, sizeof(TLogPalette) + (nColors * sizeof(TPaletteEntry)));
    lpPalette^.palVersion := $300;
    lpPalette^.palNumEntries := nColors;
    byRedMask := (1 shl pfd.cRedBits) - 1;
    byGreenMask := (1 shl pfd.cGreenBits) - 1;
    byBlueMask := (1 shl pfd.cBlueBits) - 1;
    for i := 0 to nColors - 1 do
    begin
      lpPalette^.palPalEntry[i].peRed := (((i shr pfd.cRedShift) and byRedMask) * 255) div byRedMask;
      lpPalette^.palPalEntry[i].peGreen := (((i shr pfd.cGreenShift) and byGreenMask) * 255) div byGreenMask;
      lpPalette^.palPalEntry[i].peBlue := (((i shr pfd.cBlueShift) and byBlueMask) * 255) div byBlueMask;
      lpPalette^.palPalEntry[i].peFlags := 0;
    end;
    myPalette := CreatePalette(lpPalette^);
    HeapFree(hHeap, 0, lpPalette);
    if (myPalette <> 0) then
    begin
      SelectPalette(myDC, myPalette, False);
      RealizePalette(myDC);
    end;
  end;
end;

procedure render_rpy_guide(roll, pitch, yaw: Real);
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  // Set the camera/viewpoint
  gluLookAt(0.0, 0.0, 5.0,  // Camera position
            0.0, 0.0, 0.0,  // Look-at point
            0.0, 1.0, 0.0); // Up vector

  glRotatef(yaw, 0.0, 0.0, 1.0);
  glRotatef(pitch, 0.0, 1.0, 0.0);
  glRotatef(roll, 1.0, 0.0, 0.0);

  // X-axis (Roll) - Red
  glColor3f(1.0, 0.0, 0.0);
  glBegin(GL_LINES);
    glVertex3f(0.0, 0.0, 0.0);
    glVertex3f(2.0, 0.0, 0.0);
  glEnd;

  // Y-axis (Pitch) - Green
  glColor3f(0.0, 1.0, 0.0);
  glBegin(GL_LINES);
    glVertex3f(0.0, 0.0, 0.0);
    glVertex3f(0.0, 2.0, 0.0);
  glEnd;

  // Z-axis (Yaw) - Blue
  glColor3f(0.0, 0.0, 1.0);
  glBegin(GL_LINES);
    glVertex3f(0.0, 0.0, 0.0);
    glVertex3f(0.0, 0.0, 2.0);
  glEnd;

  SwapBuffers(wglGetCurrentDC);
end;

procedure render_cyl;
begin
  glClearColor(0.7, 0.7, 0.7, 1.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glenable(gl_lighting);
  gltranslate(x_pos, y_pos, z_pos);
  glrotate(pitch, 0, 0, 1);
  glrotate(yaw, 0, 1, 0);
  glrotate(roll, 1, 0, 0);

  glrotate(rotation_angle, 0, 0, 1);
  glucylinder(cylinder, 0.5, 0.5, 2.5, 32, 32);
  gludisk(disk, 0, 0.5, 12, 32);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 0, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 60, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 120, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 180, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 240, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 300, 30);
  glpushmatrix();
  gltranslate(0, 0, 2.5);
  gludisk(disk, 0, 0.5, 12, 32);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 0, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 60, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 120, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 180, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 240, 30);
  glupartialdisk(partial_disk, 0.5, 0.75, 12, 32, 300, 30);
  glpopmatrix();
  swapBuffers(form1.myDC);
end;

procedure render_two_upper;
var
  length, length_1, tp, tl, tt, finger_p, finger_p1, finger_p2, finger_space: real;
begin
  glClearColor(0.7, 0.7, 0.7, 1.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glenable(gl_lighting);
  gltranslate(x_pos, y_pos, z_pos);
  glrotate(pitch, 0, 0, 1); // rotation on z axis
  glrotate(yaw, 0, 1, 0); // rotation on y axis
  glrotate(roll, 1, 0, 0); // rotation on x axis

  length := 4;
  length_1 := 3;
  tp := 1.25;
  tl := 0.5;
  tt := 0.175;

  glrotate(90, 1, 0, 0);
  glrotate(rotation_angle, 0, 1, 0);
  glrotate(rotation_angle, 1, 0, 0);

  glusphere(sphere, 1.0, 32, 32);
  gluCylinder(cylinder, 0.65, 0.35, length / 2, 32, 32);
  glpushmatrix();
  gltranslate(0, 0, length / 2);

  glusphere(sphere, 1.0, 32, 32);
  glrotate(90, 0, 1, 0);
  glucylinder(cylinder, 0.65, 0.65, length / 2, 32, 32);
  gltranslate(0, 0, length / 2);
  glusphere(sphere, 1.0, 32, 32);
  glpopmatrix();

  glpushmatrix();
  glrotate(rotation_angle1, 0, 1, 0);
  gluCylinder(cylinder, 0.65, 0.35, length, 32, 32);

  gltranslate(0, 0, length);
  glusphere(sphere, 1.0, 32, 32);
  glpopmatrix();
  glpushmatrix();
  glrotate(-120, 0, 1, 0);
  gluCylinder(cylinder, 0.65, 0.35, length, 32, 32);

  gltranslate(0, 0, length);
  glusphere(sphere, 1, 32, 32);
  glpopmatrix();
  glpushmatrix();
  glrotate(-270, 0, 1, 0);
  gluCylinder(cylinder, 0.65, 0.35, length, 32, 32);
  gltranslate(0, 0, length);
  glusphere(sphere, 1, 32, 32);
  glpopmatrix();
  swapBuffers(form1.myDC);
end;

procedure render_upper_limb;
var
  length, length_1, tp, tl, tt, finger_p, finger_p1, finger_p2, fingerspace: real;
begin
  glClearColor(0.7, 0.7, 0.7, 1.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glenable(gl_lighting);
  gltranslate(x_pos, y_pos, z_pos);
  glrotate(pitch, 0, 0, 1);
  glrotate(yaw, 0, 1, 0);
  glrotate(roll, 1, 0, 0);
  length := 4;
  length_1 := 3;
  tp := 1.25;
  tl := 0.5;
  tt := 0.175;
  glrotate(90, 0, 1, 0);
  glrotate(rotation_angle, 0, 1, 0);   // rotation of the whole model
  glrotate(rotation_angle, 1, 0, 0);

  glpushmatrix();
  glusphere(sphere, 1.0, 32, 32);
  gluCylinder(cylinder, 0.65, 0.35, length, 32, 32);
  glusphere(sphere, 0.5, 32, 32);

  glrotate(1.5 * rotation_angle, 1, 0, 0);  // rotation of the lower limb
  glpushmatrix();
  gluCylinder(cylinder, 0.35, 0.35, length_1, 32, 32);
  gltranslate(0, 0, length_1);

  glrotate(2 * rotation_angle, 1, 0, 0);  // rotation of the end-effector
  glusphere(sphere, 0.4, 32, 32);
  glpushmatrix();
  gluCylinder(cylinder, 0.55, 0.55, 0.75, 32, 32);
  gltranslate(0, 0, 0.75);
  glusphere(sphere, 0.55, 32, 32);
  glpopmatrix();
  swapBuffers(form1.myDC);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  theta := 30 * pi / 180;
  phi := 20 * pi / 180;
  theta_dot := 0;
  phi_dot := 0;

  form1.myDC := GetDC(Handle);
  SetupPixelFormat;
  myRC := wglCreateContext(myDC);
  wglMakeCurrent(myDC, myRC);
  glEnable(GL_DEPTH_TEST);
  glLoadIdentity;

  glClearColor(0.0, 0.0, 0.0, 1.0);
  glShadeModel(GL_SMOOTH);
  glClearDepth(1.0);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

  glEnable(GL_TEXTURE_2D);

  sphere := gluNewQuadric();
  cylinder := gluNewQuadric();
  disk := glunewquadric();
  partial_disk := glunewquadric();

  gluQuadricNormals(sphere, GLU_SMOOTH);
  gluQuadricNormals(cylinder, GLU_SMOOTH);
  gluQuadricNormals(disk, GLU_SMOOTH);

  glMaterialfv(GL_FRONT, GL_SPECULAR, @mat_specular);
  glMaterialfv(GL_BACK, GL_SPECULAR, @mat_specular);
  glMaterialfv(GL_FRONT, GL_SHININESS, @mat_shininess);
  glMaterialfv(GL_BACK, GL_SHININESS, @mat_shininess);
  glLightfv(GL_LIGHT0, GL_POSITION, @light_position);
  glLightfv(GL_LIGHT3, GL_SPECULAR, @mat_specular);
  glLightfv(GL_LIGHT1, GL_POSITION, @light_position);
  glLightfv(GL_LIGHT2, GL_POSITION, @light_position);

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);
  glEnable(GL_LIGHT2);
  glEnable(GL_LIGHT3);
  glDepthFunc(GL_LEQUAL);

  rotation_angle := 0;
  rotation_angle1 := 0;
  rotation_angle2 := 0;
  rotation_angle3 := 0;
  x_pos := 3;
  y_pos := 0;
  z_pos := -15;

  rb1.Checked := True;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if upper_limb then
    render_upper_limb
  else if two_upper then
    render_two_upper
  else if cyl then
    render_cyl;
//  render_rpy_guide(roll, pitch, yaw);
  time := time + 0.01;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  wglmakecurrent(0, 0);
  wgldeletecontext(mydc);
  releasedc(handle, mydc);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  glViewport(0, 0, Width, Height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(45.0, Width / Height, 1, 100.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  rotation_angle1 := 90 * sin(2 * pi * f0 * time);
  rotation_angle := 90 * abs(sin(2 * pi * f1 * time));
  rotation_angle3 := 180 * abs(sin(2 * pi * f2 * time));
  rotation_angle2 := 90 * abs(sin(0.1 * time));
  lnsrsSeries1.addxy(time, rotation_angle);
  lnsrsSeries2.addxy(time, rotation_angle3);
  x_pos := x_pos + 0.005 * cos(rotation_angle * pi / 180);
end;

procedure TForm1.se1Change(Sender: TObject);
begin
  pitch := se1.value;
end;

procedure TForm1.se2Change(Sender: TObject);
begin
  yaw := se2.Value;
end;

procedure TForm1.se3Change(Sender: TObject);
begin
  roll := se3.value;
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  lnsrsSeries1.Clear;
  lnsrsSeries2.Clear;

  if rb1.Checked then
  begin
    upper_limb := True;
    two_upper := False;
    cyl := False;
  end
  else if rb2.Checked then
  begin
    upper_limb := False;
    two_upper := True;
    cyl := False;
  end
  else if rb3.Checked then
  begin
    upper_limb := False;
    two_upper := False;
    cyl := True;
  end;

  timer1.Enabled := True;
  timer2.Enabled := True;
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  timer1.Enabled := False;
  timer2.Enabled := False;
  upper_limb := False;
  two_upper := False;
  cyl := False;
end;

end.

