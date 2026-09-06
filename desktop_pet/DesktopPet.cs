using System;
using System.Collections.Generic;
using System.IO;
using System.Diagnostics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace NoteProDesktopPet
{
    public class DeadlineItem
    {
        public string id { get; set; }
        public string title { get; set; }
        public string dueTime { get; set; }
        public bool isOverdue { get; set; }
    }

    public enum PetState
    {
        Idle,
        Walking,
        Happy,
        Panicking,
        Sleeping,
        Celebrating,
        BeingDragged
    }

    public class PetWindow : Window
    {
        // Timers for behaviors
        private DispatcherTimer _behaviorTimer;
        private DispatcherTimer _syncTimer;
        private DispatcherTimer _speechTimer;
        private DispatcherTimer _blinkTimer;
        private DispatcherTimer _earTwitchTimer;
        private Random _random = new Random();

        private PetState _state = PetState.Idle;
        private bool _facingRight = true;
        private bool _isCelebrating = false;
        private bool _isOverdue = false;

        // Selected Pet Type: "dog" | "cat" | "anime" | "cyber" | "reaper"
        private string _petType = "dog";

        // Cyber idle sprite animation frames
        private List<BitmapImage> _cyberIdleFrames = new List<BitmapImage>();
        private DispatcherTimer _cyberAnimTimer;
        private int _cyberCurrentFrame = 0;
        private Image _cyberImageControl;

        // Smooth Dragging state
        private bool _isDragging = false;
        private Point _dragStartMouse;
        private Point _dragStartWindow;
        private double _dragDistance = 0;

        // UI & Transform Elements
        private Canvas _fxCanvas;
        private Border _speechBubble;
        private TextBlock _txtTitle;
        private TextBlock _txtMessage;
        private TextBlock _txtTask;
        private Button _btnComplete;
        private Button _btnSwitchPet;
        private Grid _petRoot;

        // Animated Transforms
        private ScaleTransform _flipTransform;
        private TranslateTransform _bounceTransform;
        private RotateTransform _tiltTransform;
        private ScaleTransform _bodyBreatheTransform;
        private RotateTransform _tailRotateTransform;
        private RotateTransform _leftEarRotate;
        private RotateTransform _rightEarRotate;
        private ScaleTransform _eyesScaleY;
        private TranslateTransform _tongueY;
        private TranslateTransform _leftPawY;
        private TranslateTransform _rightPawY;
        private RotateTransform _bellRotate;
        private RotateTransform _scytheRotate;
        private TextBlock _sleepZ;

        private string _statePath;
        private string _actionPath;
        private DeadlineItem _currentDeadline;
        private int _speechIndex = 0;

        // Dialogue libraries
        private string[] _dogPhrasesNormal = new string[]
        {
            "Gâu gâu! Chủ nhân ơi, có việc sắp đến hạn nè! 🐶🐾",
            "Cố lên nào chủ nhân ơi, mình tin bạn làm được mà! Woof woof! 🦴",
            "Đừng nản lòng nha, làm xong việc rồi xoa đầu mình nhé! ✨",
            "Gâu! Mau bấm [✓ Hoàn thành!] để mình thưởng khúc xương nha! 🍖",
            "Chủ nhân làm việc chăm chỉ quá, mình ngồi canh cho nè! 💖"
        };
        private string[] _dogPhrasesPanic = new string[]
        {
            "Gâu gâu gâu!! Trễ hạn mất rồi chủ nhân ơi, mau nộp thôi!! 😭💦",
            "Báo động đỏ! Việc này quá hạn rồi kìa chủ nhân ơi!! 🚨",
            "Gâu gâu! Lo lắng quá đi mất, chủ nhân mau hoàn thành nhé! 🥺"
        };

        private string[] _catPhrasesNormal = new string[]
        {
            "Meo meo~ Chủ nhân ơi! Có việc sắp đến hạn kìa! 🐾",
            "Đừng lười nha, làm xong rồi vuốt ve mình nha meo~ 😺💖",
            "Mình nằm đây trông bạn làm việc thật chăm chỉ nè! ✨",
            "Bấm [✓ Hoàn thành!] để giải cứu deadline nhé! ⏰"
        };
        private string[] _catPhrasesPanic = new string[]
        {
            "Ối dồi ôi! Việc này quá hạn rồi chủ nhân ơi!! 😭💦",
            "Hạn chót trễ rồi kìa, mau hoàn thành đi nha!! 🚨",
            "Mình lo lắng đến toát mồ hôi hột rồi nè meo! 🥺"
        };

        private string[] _animePhrasesNormal = new string[]
        {
            "Senpai ơi! Bạn có việc sắp đến hạn nè, cố lên nhé! (◕‿◕✿)",
            "Đừng lười nha Senpai, mình sẽ đứng đây cổ vũ bạn làm xong mới thôi đó! 💕",
            "Mau bấm [✓ Hoàn thành!] để mình được vui nha Senpai~ ✨",
            "Nếu mệt thì nghỉ 5 phút uống nước rồi làm tiếp nha Senpai! 🍵"
        };
        private string[] _animePhrasesPanic = new string[]
        {
            "Oa oa!! Trễ hạn mất rồi Senpai ơi, mau nộp thôi nào! 😭💦",
            "Chết rồi chết rồi, việc này bị quá hạn rồi Senpai ơi!! 🚨",
            "Senpai ơi mau hoàn thành việc này đi mà, mình lo lắm á! 🥺"
        };

        private string[] _cyberPhrasesNormal = new string[]
        {
            "Bíp bíp! Hệ thống phát hiện nhiệm vụ sắp đến hạn nè Master! ⚡💻",
            "Master ơi, đừng lười nha! Em đã bật chế độ hỗ trợ tối đa rồi nè! 🚀✨",
            "Nhiệm vụ đang chờ xác nhận! Bấm [✓ Hoàn thành!] để nạp năng lượng cho em nha! 🔋💖",
            "Đang quét tiến độ... Master làm việc chăm chỉ điểm 10 luôn! 🌟",
            "Nếu căng thẳng quá thì để em phát nhạc thư giãn cho Master nha! 🎧💙"
        };
        private string[] _cyberPhrasesPanic = new string[]
        {
            "BÁO ĐỘNG ĐỎ!! 🚨 Phát hiện DEADLINE đã quá hạn! Kích hoạt chế độ khẩn cấp! ⚡💦",
            "Master ơi trễ hạn rồi kìa!! CPU của em đang nóng rực 100°C rồi nè!! 😭🔥",
            "Cảnh báo quá hạn mức độ cao! Mau giải quyết deadline ngay thôi Master ơi! ⚠️🚨"
        };

        private string[] _reaperPhrasesNormal = new string[]
        {
            "Ngươi có biết vì sao ta xuất hiện không? DEADLINE sắp tới rồi đấy! 💀⏳",
            "Lưỡi hái của ta đã mài sắc bén... Mau làm việc trước khi ta thu hoạch ngươi! ⚡",
            "Thời gian đang cạn dần từng hạt cát... Đừng để ta phải vung hái nha! 👻",
            "Mau bấm [✓ Hoàn thành!] để xua đuổi ta đi nào, người phàm trần! 🕯️",
            "Ta đang đứng canh chừng ngươi đấy, làm cho tử tế vào nhé! 💀"
        };
        private string[] _reaperPhrasesPanic = new string[]
        {
            "HAHAHA! TRỄ HẠN RỒI! Giờ đền mạng... à nhầm, đền DEADLINE đã đến!! 💀🚨",
            "Hạn chót đã điểm! Mau hoàn thành ngay trước khi bị lưỡi hái phạt! ⚔️🔥",
            "Ngươi đã đánh thức cơn thịnh nộ của Thần Chết rồi đó!! Mau làm đi! ⚡💀"
        };

        public PetWindow()
        {
            Title = "NoteCards Desktop Pet";
            WindowStyle = WindowStyle.None;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            Topmost = true;
            ShowInTaskbar = false;
            Width = 320;
            Height = 270;

            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            string[] candidateDirs = new string[]
            {
                System.IO.Path.Combine(appData, "com.notepro.app", "notepro", "NoteProData"),
                System.IO.Path.Combine(appData, "com.example", "notepro", "NoteProData"),
                System.IO.Path.Combine(appData, "NoteProData")
            };

            string dataDir = candidateDirs[0];
            foreach (string candidate in candidateDirs)
            {
                if (System.IO.File.Exists(System.IO.Path.Combine(candidate, "pet_state.json")))
                {
                    dataDir = candidate;
                    break;
                }
            }

            if (!System.IO.Directory.Exists(dataDir))
            {
                System.IO.Directory.CreateDirectory(dataDir);
            }
            _statePath = System.IO.Path.Combine(dataDir, "pet_state.json");
            _actionPath = System.IO.Path.Combine(dataDir, "pet_action.json");

            double screenWidth = SystemParameters.WorkArea.Width;
            double screenHeight = SystemParameters.WorkArea.Height;
            Left = Math.Max(50, screenWidth - 380);
            Top = Math.Max(50, screenHeight - 280);

            PreviewMouseLeftButtonDown += OnPreviewMouseLeftButtonDown;
            PreviewMouseMove += OnPreviewMouseMove;
            PreviewMouseLeftButtonUp += OnPreviewMouseLeftButtonUp;

            Log("PetWindow constructor: calling BuildUI");
            BuildUI();
            Log("PetWindow constructor: calling SyncFromStateFile");
            SyncFromStateFile();
            Log("PetWindow constructor: calling ApplyPetGraphic");
            ApplyPetGraphic();
            Log("PetWindow constructor: calling SetupContinuousAnimations");
            SetupContinuousAnimations();
            Log("PetWindow constructor: calling StartTimers");
            StartTimers();
            Closing += (s, e) => Log("PetWindow Closing fired! Cancel=" + e.Cancel);
            Closed += (s, e) => Log("PetWindow Closed event fired! Stack: " + Environment.StackTrace);
            Loaded += (s, e) => Log("PetWindow Loaded fired!");
            Unloaded += (s, e) => Log("PetWindow Unloaded fired!");
            Log("PetWindow constructor finished successfully");
        }

        private void OnPreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            DependencyObject current = e.OriginalSource as DependencyObject;
            while (current != null && current != this)
            {
                if (current is Button) return;
                current = VisualTreeHelper.GetParent(current);
            }

            _behaviorTimer.Stop();

            double currentLeft = Left;
            double currentTop = Top;
            BeginAnimation(Window.LeftProperty, null);
            BeginAnimation(Window.TopProperty, null);
            Left = currentLeft;
            Top = currentTop;

            _isDragging = true;
            _dragDistance = 0;
            _dragStartMouse = PointToScreen(e.GetPosition(this));
            _dragStartWindow = new Point(currentLeft, currentTop);

            SetPetState(PetState.BeingDragged);
            SpawnParticle(160, 180);

            CaptureMouse();
        }

        private void OnPreviewMouseMove(object sender, MouseEventArgs e)
        {
            if (_isDragging && e.LeftButton == MouseButtonState.Pressed)
            {
                Point currentMouse = PointToScreen(e.GetPosition(this));
                double dx = currentMouse.X - _dragStartMouse.X;
                double dy = currentMouse.Y - _dragStartMouse.Y;
                _dragDistance = Math.Sqrt(dx * dx + dy * dy);

                Left = _dragStartWindow.X + dx;
                Top = _dragStartWindow.Y + dy;

                if (Math.Abs(dx) > 3)
                {
                    _facingRight = dx > 0;
                    _flipTransform.ScaleX = _facingRight ? -1 : 1;
                }

                _tiltTransform.Angle = Math.Max(-15, Math.Min(15, dx * 0.15));
                _bounceTransform.Y = -14;
            }
        }

        private void OnPreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            if (_isDragging)
            {
                _isDragging = false;
                ReleaseMouseCapture();

                _tiltTransform.Angle = 0;

                if (_dragDistance < 5)
                {
                    _speechBubble.Visibility = _speechBubble.Visibility == Visibility.Visible
                        ? Visibility.Collapsed
                        : Visibility.Visible;
                    SpawnParticle(160, 160);
                }

                DoubleAnimation landingAnim = new DoubleAnimation
                {
                    From = -14,
                    To = 0,
                    Duration = TimeSpan.FromMilliseconds(380),
                    EasingFunction = new BounceEase { Bounces = 2, Bounciness = 4 }
                };
                _bounceTransform.BeginAnimation(TranslateTransform.YProperty, landingAnim);

                SetPetState(PetState.Idle);
                _behaviorTimer.Start();
            }
        }

        private void BuildUI()
        {
            Grid mainGrid = new Grid();

            _fxCanvas = new Canvas { IsHitTestVisible = false };
            mainGrid.Children.Add(_fxCanvas);

            // Speech Bubble (Top)
            _speechBubble = new Border
            {
                Width = 295,
                Background = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                CornerRadius = new CornerRadius(16),
                BorderBrush = new SolidColorBrush(Color.FromRgb(245, 158, 11)),
                BorderThickness = new Thickness(2.0),
                Padding = new Thickness(12, 10, 12, 10),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                Margin = new Thickness(0, 0, 0, 10),
                Effect = new System.Windows.Media.Effects.DropShadowEffect
                {
                    Color = Colors.Black,
                    BlurRadius = 14,
                    Opacity = 0.55,
                    ShadowDepth = 4
                }
            };

            StackPanel bubbleContent = new StackPanel();

            // Bubble Header
            Grid headerGrid = new Grid();
            _txtTitle = new TextBlock
            {
                Text = "🐶 CÚN CON NHẮC DEADLINE",
                FontSize = 11.5,
                FontWeight = FontWeights.Bold,
                Foreground = new SolidColorBrush(Color.FromRgb(245, 158, 11))
            };
            Button btnCloseBubble = new Button
            {
                Content = "✕",
                FontSize = 10,
                Width = 20,
                Height = 20,
                Background = Brushes.Transparent,
                Foreground = Brushes.LightGray,
                BorderThickness = new Thickness(0),
                HorizontalAlignment = HorizontalAlignment.Right,
                Cursor = Cursors.Hand
            };
            btnCloseBubble.Click += (s, e) => _speechBubble.Visibility = _speechBubble.Visibility == Visibility.Visible ? Visibility.Collapsed : Visibility.Visible;

            headerGrid.Children.Add(_txtTitle);
            headerGrid.Children.Add(btnCloseBubble);
            bubbleContent.Children.Add(headerGrid);

            // Speech text
            _txtMessage = new TextBlock
            {
                Text = "",
                FontSize = 12,
                Foreground = Brushes.WhiteSmoke,
                TextWrapping = TextWrapping.Wrap,
                Margin = new Thickness(0, 4, 0, 4)
            };
            bubbleContent.Children.Add(_txtMessage);

            // Task Name Box
            Border taskBox = new Border
            {
                Background = new SolidColorBrush(Color.FromArgb(60, 255, 255, 255)),
                CornerRadius = new CornerRadius(8),
                Padding = new Thickness(8, 5, 8, 5),
                Margin = new Thickness(0, 2, 0, 6)
            };
            _txtTask = new TextBlock
            {
                Text = "Công việc sắp đến hạn",
                FontSize = 12.5,
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(Color.FromRgb(254, 240, 138)),
                TextTrimming = TextTrimming.CharacterEllipsis
            };
            taskBox.Child = _txtTask;
            bubbleContent.Children.Add(taskBox);

            // Buttons: [Xong việc], [🐾 Đổi Pet], and [Mở App]
            StackPanel btnRow = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };

            _btnComplete = new Button
            {
                Content = "✓ Hoàn thành!",
                FontSize = 11,
                FontWeight = FontWeights.Bold,
                Background = new SolidColorBrush(Color.FromRgb(16, 185, 129)),
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Padding = new Thickness(8, 4, 8, 4),
                Margin = new Thickness(0, 0, 6, 0),
                Cursor = Cursors.Hand
            };
            _btnComplete.Click += (s, e) => MarkTaskCompleted();

            _btnSwitchPet = new Button
            {
                Content = "🐾 Đổi Pet",
                FontSize = 11,
                Background = new SolidColorBrush(Color.FromRgb(79, 70, 229)), // Indigo
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Padding = new Thickness(8, 4, 8, 4),
                Margin = new Thickness(0, 0, 6, 0),
                Cursor = Cursors.Hand
            };
            _btnSwitchPet.Click += (s, e) => CyclePetType();

            Button btnOpenApp = new Button
            {
                Content = "Mở App",
                FontSize = 11,
                Background = new SolidColorBrush(Color.FromArgb(80, 255, 255, 255)),
                Foreground = Brushes.White,
                BorderThickness = new Thickness(0),
                Padding = new Thickness(8, 4, 8, 4),
                Cursor = Cursors.Hand
            };
            btnOpenApp.Click += (s, e) => OpenNoteProApp();

            btnRow.Children.Add(_btnComplete);
            btnRow.Children.Add(_btnSwitchPet);
            btnRow.Children.Add(btnOpenApp);
            bubbleContent.Children.Add(btnRow);

            _speechBubble.Child = bubbleContent;
            mainGrid.Children.Add(_speechBubble);

            // Pet Root
            _petRoot = new Grid
            {
                Width = 114,
                Height = 108,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Bottom,
                Cursor = Cursors.SizeAll,
                RenderTransformOrigin = new Point(0.5, 0.85)
            };

            TransformGroup tg = new TransformGroup();
            _flipTransform = new ScaleTransform(1, 1);
            _bounceTransform = new TranslateTransform(0, 0);
            _tiltTransform = new RotateTransform(0);
            tg.Children.Add(_flipTransform);
            tg.Children.Add(_bounceTransform);
            tg.Children.Add(_tiltTransform);
            _petRoot.RenderTransform = tg;

            mainGrid.Children.Add(_petRoot);
            Content = mainGrid;
        }

        private void CyclePetType()
        {
            if (_petType == "dog") _petType = "cat";
            else if (_petType == "cat") _petType = "anime";
            else if (_petType == "anime") _petType = "cyber";
            else if (_petType == "cyber") _petType = "reaper";
            else _petType = "dog";

            ApplyPetGraphic();
            SetupContinuousAnimations();
            CycleSpeechText();
            SpawnParticle(160, 160);

            try
            {
                string actionJson = "{\"action\":\"switch_pet\",\"petType\":\"" + _petType + "\",\"timestamp\":\"" + DateTime.Now.ToString("o") + "\"}";
                File.WriteAllText(_actionPath, actionJson);
            }
            catch { }
        }

        private void ApplyPetGraphic()
        {
            _petRoot.Children.Clear();
            if (_petType != "cyber" && _cyberAnimTimer != null) _cyberAnimTimer.Stop();

            if (_petType == "cat")
            {
                DrawKawaiiCatGraphic(_petRoot);
                _txtTitle.Text = _isOverdue ? "🚨 DEADLINE ĐÃ QUÁ HẠN!" : "🐾 MÈO CON NHẮC DEADLINE";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(99, 102, 241));
                _speechBubble.BorderBrush = _isOverdue ? Brushes.Red : new SolidColorBrush(Color.FromRgb(99, 102, 241));
            }
            else if (_petType == "anime")
            {
                DrawAnimeGirlGraphic(_petRoot);
                _txtTitle.Text = _isOverdue ? "🚨 DEADLINE ĐÃ QUÁ HẠN!" : "🌸 BÉ TRỢ LÝ ANIME NHẮC VIỆC";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(244, 114, 182));
                _speechBubble.BorderBrush = _isOverdue ? Brushes.Red : new SolidColorBrush(Color.FromRgb(244, 114, 182));
            }
            else if (_petType == "cyber")
            {
                DrawCyberGirlGraphic(_petRoot);
                _txtTitle.Text = _isOverdue ? "🚨 DEADLINE ĐÃ QUÁ HẠN!" : "⚡ BÉ CYBER NEKO NHẮC VIỆC";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(6, 182, 212));
                _speechBubble.BorderBrush = _isOverdue ? Brushes.Red : new SolidColorBrush(Color.FromRgb(6, 182, 212));
            }
            else if (_petType == "reaper")
            {
                DrawGrimReaperGraphic(_petRoot);
                _txtTitle.Text = _isOverdue ? "🚨 TỬ THẦN ĐẾN ĐÒI DEADLINE!" : "💀 THẦN CHẾT NHẮC DEADLINE";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(168, 85, 247)); // Purple
                _speechBubble.BorderBrush = _isOverdue ? Brushes.Red : new SolidColorBrush(Color.FromRgb(168, 85, 247));
            }
            else // Default: dog
            {
                DrawCutePuppyGraphic(_petRoot);
                _txtTitle.Text = _isOverdue ? "🚨 DEADLINE ĐÃ QUÁ HẠN!" : "🐶 CÚN CON NHẮC DEADLINE";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(245, 158, 11));
                _speechBubble.BorderBrush = _isOverdue ? Brushes.Red : new SolidColorBrush(Color.FromRgb(245, 158, 11));
            }
            UpdateSpeechText(false);
        }

        // ==================== 1. CUTE PUPPY (SHIBA / CORGI) ====================
        private void DrawCutePuppyGraphic(Grid root)
        {
            Color furGold = Color.FromRgb(245, 158, 11); // Honey Amber Shiba Fur
            Color furCream = Color.FromRgb(255, 252, 245); // Cream White Muzzle & Cheeks
            Color darkBrown = Color.FromRgb(69, 44, 25); // Soft Warm Cocoa Outline
            Color earPink = Color.FromRgb(254, 205, 211); // Pastel Pink Inner Ear

            // 1. Cute Curled Wagging Tail (Back)
            System.Windows.Shapes.Path tail = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 16 60 C 6 48, 0 34, 8 24 C 15 16, 22 22, 19 34 C 17 44, 21 54, 24 60 Z"),
                Fill = new SolidColorBrush(furGold),
                Stroke = new SolidColorBrush(darkBrown),
                StrokeThickness = 2.2,
                RenderTransformOrigin = new Point(0.85, 0.95)
            };
            _tailRotateTransform = new RotateTransform(0);
            tail.RenderTransform = _tailRotateTransform;
            root.Children.Add(tail);

            // 2. Beautiful Curved Shiba Dog Ears (Tai cún bo cong mềm mại)
            // Left Ear
            Grid leftEarGrid = new Grid
            {
                Width = 28,
                Height = 34,
                Margin = new Thickness(14, 2, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.85, 0.95)
            };
            _leftEarRotate = new RotateTransform(-8);
            leftEarGrid.RenderTransform = _leftEarRotate;

            System.Windows.Shapes.Path leftEar = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 24 32 C 20 18, 12 8, 4 4 C 14 0, 24 6, 27 22 Z"),
                Fill = new SolidColorBrush(furGold),
                Stroke = new SolidColorBrush(darkBrown),
                StrokeThickness = 2.2,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round,
                StrokeLineJoin = PenLineJoin.Round
            };
            System.Windows.Shapes.Path leftEarInner = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 22 28 C 18 16, 12 9, 7 6 C 14 4, 21 9, 24 20 Z"),
                Fill = new SolidColorBrush(earPink)
            };
            leftEarGrid.Children.Add(leftEar);
            leftEarGrid.Children.Add(leftEarInner);
            root.Children.Add(leftEarGrid);

            // Right Ear
            Grid rightEarGrid = new Grid
            {
                Width = 28,
                Height = 34,
                Margin = new Thickness(62, 2, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.15, 0.95)
            };
            _rightEarRotate = new RotateTransform(8);
            rightEarGrid.RenderTransform = _rightEarRotate;

            System.Windows.Shapes.Path rightEar = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 4 32 C 8 18, 16 8, 24 4 C 14 0, 4 6, 1 22 Z"),
                Fill = new SolidColorBrush(furGold),
                Stroke = new SolidColorBrush(darkBrown),
                StrokeThickness = 2.2,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round,
                StrokeLineJoin = PenLineJoin.Round
            };
            System.Windows.Shapes.Path rightEarInner = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 6 28 C 10 16, 16 9, 21 6 C 14 4, 7 9, 4 20 Z"),
                Fill = new SolidColorBrush(earPink)
            };
            rightEarGrid.Children.Add(rightEar);
            rightEarGrid.Children.Add(rightEarInner);
            root.Children.Add(rightEarGrid);

            // 3. Body & Head Container with Breathing Scale
            Grid bodyHead = new Grid
            {
                Width = 80,
                Height = 72,
                Margin = new Thickness(0, 10, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.9)
            };
            _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
            bodyHead.RenderTransform = _bodyBreatheTransform;

            // Chubby Golden Head
            Border headBorder = new Border
            {
                Width = 80,
                Height = 68,
                CornerRadius = new CornerRadius(38, 38, 34, 34),
                Background = new SolidColorBrush(furGold),
                BorderBrush = new SolidColorBrush(darkBrown),
                BorderThickness = new Thickness(2.4),
                Effect = new System.Windows.Media.Effects.DropShadowEffect
                {
                    Color = Colors.Black,
                    BlurRadius = 10,
                    Opacity = 0.35,
                    ShadowDepth = 2
                }
            };
            bodyHead.Children.Add(headBorder);

            // Classic Shiba Inu White Eyebrow Dots (Đốm lông mày tròn trắng đặc trưng)
            Ellipse leftBrowDot = new Ellipse
            {
                Width = 8,
                Height = 6,
                Fill = new SolidColorBrush(furCream),
                Margin = new Thickness(22, 17, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            };
            Ellipse rightBrowDot = new Ellipse
            {
                Width = 8,
                Height = 6,
                Fill = new SolidColorBrush(furCream),
                Margin = new Thickness(0, 17, 22, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top
            };
            bodyHead.Children.Add(leftBrowDot);
            bodyHead.Children.Add(rightBrowDot);

            // Chubby White Muzzle & Cheeks (Vòm mõm trắng mịn cong tròn)
            Border whiteMuzzle = new Border
            {
                Width = 56,
                Height = 38,
                CornerRadius = new CornerRadius(28, 28, 24, 24),
                Background = new SolidColorBrush(furCream),
                BorderBrush = new SolidColorBrush(Color.FromArgb(50, 69, 44, 25)),
                BorderThickness = new Thickness(1.0),
                Margin = new Thickness(0, 28, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top
            };
            bodyHead.Children.Add(whiteMuzzle);

            // Eyes Grid
            Grid eyesGrid = new Grid
            {
                Width = 52,
                Height = 16,
                Margin = new Thickness(0, 25, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.5)
            };
            _eyesScaleY = new ScaleTransform(1.0, 1.0);
            eyesGrid.RenderTransform = _eyesScaleY;

            // Left Eye
            Grid leftEyeBox = new Grid { Width = 12, Height = 14, HorizontalAlignment = HorizontalAlignment.Left };
            leftEyeBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(darkBrown) });
            leftEyeBox.Children.Add(new Ellipse { Width = 4.5, Height = 5, Fill = Brushes.White, Margin = new Thickness(2, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            leftEyeBox.Children.Add(new Ellipse { Width = 2.2, Height = 2.2, Fill = Brushes.White, Margin = new Thickness(6, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            // Right Eye
            Grid rightEyeBox = new Grid { Width = 12, Height = 14, HorizontalAlignment = HorizontalAlignment.Right };
            rightEyeBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(darkBrown) });
            rightEyeBox.Children.Add(new Ellipse { Width = 4.5, Height = 5, Fill = Brushes.White, Margin = new Thickness(2, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            rightEyeBox.Children.Add(new Ellipse { Width = 2.2, Height = 2.2, Fill = Brushes.White, Margin = new Thickness(6, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            eyesGrid.Children.Add(leftEyeBox);
            eyesGrid.Children.Add(rightEyeBox);
            bodyHead.Children.Add(eyesGrid);

            // Rosy Blushing Cheeks
            bodyHead.Children.Add(new Ellipse { Width = 12, Height = 7, Fill = new SolidColorBrush(Color.FromArgb(160, 255, 120, 140)), Margin = new Thickness(6, 34, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(new Ellipse { Width = 12, Height = 7, Fill = new SolidColorBrush(Color.FromArgb(160, 255, 120, 140)), Margin = new Thickness(0, 34, 6, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });

            // Shiny Black Button Nose
            Grid noseGrid = new Grid { Width = 10, Height = 8, Margin = new Thickness(0, 34, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top };
            noseGrid.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(30, 20, 15)) });
            noseGrid.Children.Add(new Ellipse { Width = 3, Height = 2.5, Fill = Brushes.White, Margin = new Thickness(2, 1, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(noseGrid);

            // Happy Dog Smile with Pink Tongue
            Grid mouthGrid = new Grid { Width = 24, Height = 18, Margin = new Thickness(0, 41, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top };
            Border tongue = new Border { Width = 9, Height = 11, CornerRadius = new CornerRadius(0, 0, 5, 5), Background = new SolidColorBrush(Color.FromRgb(251, 113, 133)), BorderBrush = new SolidColorBrush(Color.FromRgb(225, 29, 72)), BorderThickness = new Thickness(1), Margin = new Thickness(0, 3, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top };
            _tongueY = new TranslateTransform(0, 0);
            tongue.RenderTransform = _tongueY;
            mouthGrid.Children.Add(tongue);
            mouthGrid.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 2 2 Q 6 7 12 2 Q 18 7 22 2"), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 2.0, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round, StrokeLineJoin = PenLineJoin.Round });
            bodyHead.Children.Add(mouthGrid);

            // Sky Blue Collar & Golden Bone Charm Tag
            bodyHead.Children.Add(new Rectangle { Width = 40, Height = 6, Fill = new SolidColorBrush(Color.FromRgb(14, 165, 233)), RadiusX = 3, RadiusY = 3, Margin = new Thickness(0, 56, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 4 2 C 2 0, 0 2, 2 4 C 0 6, 2 8, 4 6 L 10 6 C 12 8, 14 6, 12 4 C 14 2, 12 0, 10 2 Z"), Fill = new SolidColorBrush(Color.FromRgb(251, 191, 36)), Stroke = new SolidColorBrush(Color.FromRgb(217, 119, 6)), StrokeThickness = 1, Margin = new Thickness(0, 58, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });

            root.Children.Add(bodyHead);

            // 4. White Chubby Paws
            Grid leftPawBox = new Grid { Width = 15, Height = 11, Margin = new Thickness(22, 73, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            _leftPawY = new TranslateTransform(0, 0);
            leftPawBox.RenderTransform = _leftPawY;
            leftPawBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(furCream), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 1.8 });
            root.Children.Add(leftPawBox);

            Grid rightPawBox = new Grid { Width = 15, Height = 11, Margin = new Thickness(62, 73, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            _rightPawY = new TranslateTransform(0, 0);
            rightPawBox.RenderTransform = _rightPawY;
            rightPawBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(furCream), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 1.8 });
            root.Children.Add(rightPawBox);

            AddFXElements(root);
        }

        // ==================== 2. KAWAII KITTEN (CAT) ====================
        private void DrawKawaiiCatGraphic(Grid root)
        {
            Color catFur = Color.FromRgb(255, 252, 246);
            Color darkBrown = Color.FromRgb(74, 53, 37);

            System.Windows.Shapes.Path tail = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 16 62 C 4 50, -2 32, 6 22 C 13 15, 18 20, 16 32 C 14 44, 20 54, 24 62 Z"),
                Fill = new SolidColorBrush(Color.FromRgb(253, 186, 116)),
                Stroke = new SolidColorBrush(darkBrown),
                StrokeThickness = 2,
                RenderTransformOrigin = new Point(0.8, 0.95)
            };
            _tailRotateTransform = new RotateTransform(0);
            tail.RenderTransform = _tailRotateTransform;
            root.Children.Add(tail);

            Polygon leftEar = new Polygon { Points = new PointCollection { new Point(14, 26), new Point(22, 4), new Point(36, 22) }, Fill = new SolidColorBrush(catFur), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 2.2, StrokeLineJoin = PenLineJoin.Round, RenderTransformOrigin = new Point(0.5, 1.0) };
            _leftEarRotate = new RotateTransform(0);
            leftEar.RenderTransform = _leftEarRotate;
            Polygon innerLeftEar = new Polygon { Points = new PointCollection { new Point(17, 24), new Point(23, 9), new Point(32, 22) }, Fill = new SolidColorBrush(Color.FromRgb(255, 182, 193)), RenderTransformOrigin = new Point(0.5, 1.0) };
            innerLeftEar.RenderTransform = _leftEarRotate;

            Polygon rightEar = new Polygon { Points = new PointCollection { new Point(54, 22), new Point(68, 4), new Point(76, 26) }, Fill = new SolidColorBrush(Color.FromRgb(253, 186, 116)), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 2.2, StrokeLineJoin = PenLineJoin.Round, RenderTransformOrigin = new Point(0.5, 1.0) };
            _rightEarRotate = new RotateTransform(0);
            rightEar.RenderTransform = _rightEarRotate;
            Polygon innerRightEar = new Polygon { Points = new PointCollection { new Point(58, 22), new Point(67, 9), new Point(73, 24) }, Fill = new SolidColorBrush(Color.FromRgb(255, 182, 193)), RenderTransformOrigin = new Point(0.5, 1.0) };
            innerRightEar.RenderTransform = _rightEarRotate;

            root.Children.Add(leftEar);
            root.Children.Add(innerLeftEar);
            root.Children.Add(rightEar);
            root.Children.Add(innerRightEar);

            Grid bodyHead = new Grid { Width = 76, Height = 68, Margin = new Thickness(0, 10, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 0.9) };
            _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
            bodyHead.RenderTransform = _bodyBreatheTransform;

            Border headBorder = new Border { Width = 76, Height = 66, CornerRadius = new CornerRadius(36, 36, 32, 32), Background = new SolidColorBrush(catFur), BorderBrush = new SolidColorBrush(darkBrown), BorderThickness = new Thickness(2.2), Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Colors.Black, BlurRadius = 10, Opacity = 0.35, ShadowDepth = 2 } };
            bodyHead.Children.Add(headBorder);
            bodyHead.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 46 2 C 58 2, 72 14, 72 30 C 66 32, 54 26, 48 16 Z"), Fill = new SolidColorBrush(Color.FromRgb(253, 186, 116)), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });

            // Eyes
            Grid eyesGrid = new Grid { Width = 52, Height = 16, Margin = new Thickness(0, 26, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 0.5) };
            _eyesScaleY = new ScaleTransform(1.0, 1.0);
            eyesGrid.RenderTransform = _eyesScaleY;

            Grid leftEyeBox = new Grid { Width = 12, Height = 14, HorizontalAlignment = HorizontalAlignment.Left };
            leftEyeBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(43, 29, 20)) });
            leftEyeBox.Children.Add(new Ellipse { Width = 4.5, Height = 5, Fill = Brushes.White, Margin = new Thickness(2, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            leftEyeBox.Children.Add(new Ellipse { Width = 2.2, Height = 2.2, Fill = Brushes.White, Margin = new Thickness(7, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            Grid rightEyeBox = new Grid { Width = 12, Height = 14, HorizontalAlignment = HorizontalAlignment.Right };
            rightEyeBox.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(43, 29, 20)) });
            rightEyeBox.Children.Add(new Ellipse { Width = 4.5, Height = 5, Fill = Brushes.White, Margin = new Thickness(2, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            rightEyeBox.Children.Add(new Ellipse { Width = 2.2, Height = 2.2, Fill = Brushes.White, Margin = new Thickness(7, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            eyesGrid.Children.Add(leftEyeBox);
            eyesGrid.Children.Add(rightEyeBox);
            bodyHead.Children.Add(eyesGrid);

            bodyHead.Children.Add(new Ellipse { Width = 12, Height = 7, Fill = new SolidColorBrush(Color.FromArgb(170, 255, 110, 140)), Margin = new Thickness(6, 35, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(new Ellipse { Width = 12, Height = 7, Fill = new SolidColorBrush(Color.FromArgb(170, 255, 110, 140)), Margin = new Thickness(0, 35, 6, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(new Ellipse { Width = 5, Height = 3.5, Fill = new SolidColorBrush(Color.FromRgb(255, 120, 150)), Margin = new Thickness(0, 35, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });

            bodyHead.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 31 39 Q 34.5 43 38 39 Q 41.5 43 45 39"), Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 1.8, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round, StrokeLineJoin = PenLineJoin.Round, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 5 36 L 15 37 M 5 41 L 15 39 M 71 36 L 61 37 M 71 41 L 61 39"), Stroke = new SolidColorBrush(Color.FromRgb(150, 130, 115)), StrokeThickness = 1.2, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round });

            bodyHead.Children.Add(new Rectangle { Width = 36, Height = 6, Fill = new SolidColorBrush(Color.FromRgb(239, 68, 68)), RadiusX = 3, RadiusY = 3, Margin = new Thickness(0, 52, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });
            Grid bellGrid = new Grid { Width = 12, Height = 12, Margin = new Thickness(0, 55, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 0.1) };
            _bellRotate = new RotateTransform(0);
            bellGrid.RenderTransform = _bellRotate;
            bellGrid.Children.Add(new Ellipse { Fill = new SolidColorBrush(Color.FromRgb(251, 191, 36)), Stroke = new SolidColorBrush(Color.FromRgb(217, 119, 6)), StrokeThickness = 1.2 });
            bellGrid.Children.Add(new Ellipse { Width = 3, Height = 3, Fill = Brushes.White, Margin = new Thickness(2, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            bodyHead.Children.Add(bellGrid);

            root.Children.Add(bodyHead);

            Grid leftPawBox = new Grid { Width = 14, Height = 10, Margin = new Thickness(20, 68, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            _leftPawY = new TranslateTransform(0, 0);
            leftPawBox.RenderTransform = _leftPawY;
            leftPawBox.Children.Add(new Ellipse { Fill = Brushes.White, Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 1.6 });
            root.Children.Add(leftPawBox);

            Grid rightPawBox = new Grid { Width = 14, Height = 10, Margin = new Thickness(56, 68, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            _rightPawY = new TranslateTransform(0, 0);
            rightPawBox.RenderTransform = _rightPawY;
            rightPawBox.Children.Add(new Ellipse { Fill = Brushes.White, Stroke = new SolidColorBrush(darkBrown), StrokeThickness = 1.6 });
            root.Children.Add(rightPawBox);

            AddFXElements(root);
        }

        // ==================== 3. ANIME GIRL (CHIBI) ====================
        private void DrawAnimeGirlGraphic(Grid root)
        {
            Color hairColor = Color.FromRgb(244, 143, 177);
            Color hairOutline = Color.FromRgb(157, 23, 77);
            Color skinColor = Color.FromRgb(255, 245, 238);

            Grid leftTailGrid = new Grid { Width = 30, Height = 50, Margin = new Thickness(0, 26, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.8, 0.1) };
            _leftEarRotate = new RotateTransform(0);
            leftTailGrid.RenderTransform = _leftEarRotate;
            leftTailGrid.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 24 2 C 10 14, -2 32, 8 48 C 15 50, 22 42, 20 26 C 19 14, 26 8, 24 2 Z"), Fill = new SolidColorBrush(hairColor), Stroke = new SolidColorBrush(hairOutline), StrokeThickness = 1.8 });
            leftTailGrid.Children.Add(new Polygon { Points = new PointCollection { new Point(20, 2), new Point(12, 0), new Point(16, 7), new Point(24, 5) }, Fill = new SolidColorBrush(Color.FromRgb(99, 102, 241)) });
            root.Children.Add(leftTailGrid);

            Grid rightTailGrid = new Grid { Width = 30, Height = 50, Margin = new Thickness(74, 26, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.2, 0.1) };
            _rightEarRotate = new RotateTransform(0);
            rightTailGrid.RenderTransform = _rightEarRotate;
            rightTailGrid.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 6 2 C 20 14, 32 32, 22 48 C 15 50, 8 42, 10 26 C 11 14, 4 8, 6 2 Z"), Fill = new SolidColorBrush(hairColor), Stroke = new SolidColorBrush(hairOutline), StrokeThickness = 1.8 });
            rightTailGrid.Children.Add(new Polygon { Points = new PointCollection { new Point(10, 2), new Point(18, 0), new Point(14, 7), new Point(6, 5) }, Fill = new SolidColorBrush(Color.FromRgb(99, 102, 241)) });
            root.Children.Add(rightTailGrid);

            Grid body = new Grid { Width = 48, Height = 36, Margin = new Thickness(0, 64, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top };
            body.Children.Add(new Polygon { Points = new PointCollection { new Point(10, 16), new Point(38, 16), new Point(44, 34), new Point(4, 34) }, Fill = new SolidColorBrush(Color.FromRgb(49, 46, 129)), Stroke = new SolidColorBrush(Color.FromRgb(30, 27, 75)), StrokeThickness = 1.5 });
            body.Children.Add(new Polygon { Points = new PointCollection { new Point(13, 0), new Point(35, 0), new Point(38, 18), new Point(10, 18) }, Fill = Brushes.White, Stroke = new SolidColorBrush(Color.FromRgb(74, 53, 37)), StrokeThickness = 1.5 });
            body.Children.Add(new Polygon { Points = new PointCollection { new Point(12, 0), new Point(36, 0), new Point(31, 12), new Point(24, 5), new Point(17, 12) }, Fill = new SolidColorBrush(Color.FromRgb(79, 70, 229)) });
            body.Children.Add(new Polygon { Points = new PointCollection { new Point(20, 7), new Point(28, 7), new Point(30, 15), new Point(24, 10), new Point(18, 15) }, Fill = new SolidColorBrush(Color.FromRgb(239, 68, 68)) });
            root.Children.Add(body);

            Grid headContainer = new Grid { Width = 70, Height = 66, Margin = new Thickness(0, 6, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 0.9) };
            _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
            headContainer.RenderTransform = _bodyBreatheTransform;

            Border face = new Border { Width = 64, Height = 54, Margin = new Thickness(0, 10, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, CornerRadius = new CornerRadius(28, 28, 24, 24), Background = new SolidColorBrush(skinColor), BorderBrush = new SolidColorBrush(Color.FromRgb(74, 53, 37)), BorderThickness = new Thickness(2.0), Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Colors.Black, BlurRadius = 8, Opacity = 0.25, ShadowDepth = 2 } };
            headContainer.Children.Add(face);

            Grid eyesGrid = new Grid { Width = 44, Height = 16, Margin = new Thickness(0, 24, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 0.5) };
            _eyesScaleY = new ScaleTransform(1.0, 1.0);
            eyesGrid.RenderTransform = _eyesScaleY;

            Grid leftEye = CreateAnimeEye(true);
            leftEye.HorizontalAlignment = HorizontalAlignment.Left;
            Grid rightEye = CreateAnimeEye(false);
            rightEye.HorizontalAlignment = HorizontalAlignment.Right;
            eyesGrid.Children.Add(leftEye);
            eyesGrid.Children.Add(rightEye);
            headContainer.Children.Add(eyesGrid);

            headContainer.Children.Add(new Border { Width = 12, Height = 6, CornerRadius = new CornerRadius(6), Background = new SolidColorBrush(Color.FromArgb(170, 251, 113, 133)), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(7, 34, 0, 0) });
            headContainer.Children.Add(new Border { Width = 12, Height = 6, CornerRadius = new CornerRadius(6), Background = new SolidColorBrush(Color.FromArgb(170, 251, 113, 133)), HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 34, 7, 0) });
            headContainer.Children.Add(new Ellipse { Width = 3, Height = 2.5, Fill = new SolidColorBrush(Color.FromRgb(244, 114, 182)), Margin = new Thickness(0, 34, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });
            headContainer.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 29 38 Q 33 42 37 38"), Stroke = new SolidColorBrush(Color.FromRgb(74, 53, 37)), StrokeThickness = 1.8, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });

            headContainer.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 8 16 C 14 6, 50 6, 56 16 C 48 13, 44 20, 40 15 C 34 22, 28 15, 22 20 C 18 15, 14 18, 8 16 Z"), Fill = new SolidColorBrush(hairColor), Stroke = new SolidColorBrush(hairOutline), StrokeThickness = 1.8, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(0, 6, 0, 0) });

            Grid ahogeGrid = new Grid { Width = 22, Height = 22, Margin = new Thickness(0, -5, 10, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, RenderTransformOrigin = new Point(0.5, 1.0) };
            _tailRotateTransform = new RotateTransform(0);
            ahogeGrid.RenderTransform = _tailRotateTransform;
            ahogeGrid.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 11 22 C 5 11, 13 0, 20 2 C 15 7, 15 15, 11 22 Z"), Fill = new SolidColorBrush(hairColor), Stroke = new SolidColorBrush(hairOutline), StrokeThickness = 1.5 });
            headContainer.Children.Add(ahogeGrid);

            root.Children.Add(headContainer);
            AddFXElements(root);
        }

        private Grid CreateAnimeEye(bool isLeft)
        {
            Grid eyeBox = new Grid { Width = 13, Height = 15 };
            eyeBox.Children.Add(new System.Windows.Shapes.Path { Data = Geometry.Parse("M 0 3 Q 6 0 13 3"), Stroke = new SolidColorBrush(Color.FromRgb(30, 20, 15)), StrokeThickness = 2.0, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round });
            eyeBox.Children.Add(new Ellipse { Width = 11, Height = 12, Margin = new Thickness(1, 2, 0, 0), Fill = new LinearGradientBrush(Color.FromRgb(79, 70, 229), Color.FromRgb(147, 51, 234), new Point(0, 0), new Point(0, 1)) });
            eyeBox.Children.Add(new Ellipse { Width = 4.5, Height = 5, Fill = Brushes.White, Margin = new Thickness(isLeft ? 3 : 2, 3, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            eyeBox.Children.Add(new Ellipse { Width = 2.2, Height = 2.2, Fill = Brushes.White, Margin = new Thickness(isLeft ? 6 : 6, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            return eyeBox;
        }

        private void LoadCyberIdleFrames()
        {
            if (_cyberIdleFrames.Count > 0) return;
            string[] candidateFolders = new string[]
            {
                System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ide"),
                System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "desktop_pet", "ide"),
                "f:\\NotePro\\desktop_pet\\ide",
                "f:\\NotePro\\ide",
                System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "com.notepro.app", "notepro", "desktop_pet", "ide"),
                System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "NoteProData", "ide")
            };

            string ideDir = null;
            foreach (string dir in candidateFolders)
            {
                if (System.IO.Directory.Exists(dir))
                {
                    ideDir = dir;
                    break;
                }
            }

            if (ideDir != null)
            {
                for (int i = 1; i <= 30; i++)
                {
                    string pngPath = System.IO.Path.Combine(ideDir, string.Format("idle_{0}.png", i));
                    if (System.IO.File.Exists(pngPath))
                    {
                        try
                        {
                            BitmapImage bi = new BitmapImage();
                            bi.BeginInit();
                            bi.CacheOption = BitmapCacheOption.OnLoad;
                            bi.UriSource = new Uri(pngPath, UriKind.Absolute);
                            bi.EndInit();
                            bi.Freeze();
                            _cyberIdleFrames.Add(bi);
                        }
                        catch { }
                    }
                }
            }
        }

        private void StartCyberAnimation()
        {
            if (_cyberAnimTimer == null)
            {
                _cyberAnimTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(130) };
                _cyberAnimTimer.Tick += (s, e) =>
                {
                    if (_petType == "cyber" && _cyberImageControl != null && _cyberIdleFrames.Count > 0)
                    {
                        _cyberCurrentFrame = (_cyberCurrentFrame + 1) % _cyberIdleFrames.Count;
                        _cyberImageControl.Source = _cyberIdleFrames[_cyberCurrentFrame];
                    }
                };
            }
            _cyberAnimTimer.Start();
        }

        // ==================== 4. CYBER ANIME NEKO (BÉ MECHA WAIFU) ====================
        private void DrawCyberGirlGraphic(Grid root)
        {
            LoadCyberIdleFrames();
            if (_cyberIdleFrames.Count > 0)
            {
                Grid cyberContainer = new Grid
                {
                    Width = 120,
                    Height = 120,
                    Margin = new Thickness(0, 8, 0, 0),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Top,
                    RenderTransformOrigin = new Point(0.5, 0.9)
                };
                _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
                cyberContainer.RenderTransform = _bodyBreatheTransform;

                _cyberImageControl = new Image
                {
                    Source = _cyberIdleFrames[0],
                    Width = 120,
                    Height = 120,
                    Stretch = Stretch.Uniform
                };
                RenderOptions.SetBitmapScalingMode(_cyberImageControl, BitmapScalingMode.NearestNeighbor);
                cyberContainer.Children.Add(_cyberImageControl);

                // Floating Notification Badge (Orange Circle with "1")
                Border spriteNotifBadge = new Border
                {
                    Width = 18,
                    Height = 18,
                    CornerRadius = new CornerRadius(9),
                    Background = new LinearGradientBrush(Color.FromRgb(249, 115, 22), Color.FromRgb(234, 88, 12), new Point(0, 0), new Point(1, 1)),
                    BorderBrush = Brushes.White,
                    BorderThickness = new Thickness(1.2),
                    Margin = new Thickness(0, 6, 8, 0),
                    HorizontalAlignment = HorizontalAlignment.Right,
                    VerticalAlignment = VerticalAlignment.Top,
                    Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(234, 88, 12), BlurRadius = 6, Opacity = 0.6, ShadowDepth = 2 }
                };
                spriteNotifBadge.Child = new TextBlock
                {
                    Text = "1",
                    FontSize = 10,
                    FontWeight = FontWeights.ExtraBold,
                    Foreground = Brushes.White,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center,
                    Margin = new Thickness(0, -1, 0, 0)
                };
                cyberContainer.Children.Add(spriteNotifBadge);

                root.Children.Add(cyberContainer);
                AddFXElements(root);
                StartCyberAnimation();
                return;
            }

            Color hairWhite = Color.FromRgb(241, 245, 249); // Silver / Platinum White Hair
            Color hairShadow = Color.FromRgb(203, 213, 225); // Hair Shadow
            Color hairOutline = Color.FromRgb(71, 85, 105); // Slate Hair Outline
            Color hoodDark = Color.FromRgb(24, 24, 27); // Matte Dark Techwear Hood
            Color hoodStroke = Color.FromRgb(51, 65, 85); // Slate Techwear Outline
            Color neonCyan = Color.FromRgb(0, 229, 255); // Vibrant Cyber Neon Cyan
            Color cyanGlow = Color.FromRgb(6, 182, 212); // Cyber Cyan Accent
            Color skinColor = Color.FromRgb(255, 245, 238); // Soft Chibi Anime Skin

            // 1. Left Fluffy Silver Twin Tail (Back)
            Grid leftTailGrid = new Grid
            {
                Width = 34,
                Height = 56,
                Margin = new Thickness(0, 28, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.85, 0.12)
            };
            _leftEarRotate = new RotateTransform(0);
            leftTailGrid.RenderTransform = _leftEarRotate;

            // Fluffy Twin Tail Hair Shape
            System.Windows.Shapes.Path leftTailHair = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 26 2 C 12 12, -4 28, 4 46 C 10 54, 22 54, 26 44 C 30 34, 24 22, 27 12 C 29 6, 30 2, 26 2 Z"),
                Fill = new LinearGradientBrush(hairWhite, hairShadow, new Point(0, 0), new Point(0, 1)),
                Stroke = new SolidColorBrush(hairOutline),
                StrokeThickness = 1.8,
                StrokeLineJoin = PenLineJoin.Round
            };
            leftTailGrid.Children.Add(leftTailHair);

            // Cyber Hair Tie (Dark Clip + Cyan Glowing Band)
            leftTailGrid.Children.Add(new Rectangle { Width = 10, Height = 4, RadiusX = 2, RadiusY = 2, Fill = new SolidColorBrush(hoodDark), Stroke = new SolidColorBrush(hoodStroke), StrokeThickness = 1.2, Margin = new Thickness(18, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            leftTailGrid.Children.Add(new Rectangle { Width = 10, Height = 1.8, RadiusX = 1, RadiusY = 1, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(18, 3, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            root.Children.Add(leftTailGrid);

            // 2. Right Fluffy Silver Twin Tail (Back)
            Grid rightTailGrid = new Grid
            {
                Width = 34,
                Height = 56,
                Margin = new Thickness(76, 28, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.15, 0.12)
            };
            _rightEarRotate = new RotateTransform(0);
            rightTailGrid.RenderTransform = _rightEarRotate;

            System.Windows.Shapes.Path rightTailHair = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 8 2 C 22 12, 38 28, 30 46 C 24 54, 12 54, 8 44 C 4 34, 10 22, 7 12 C 5 6, 4 2, 8 2 Z"),
                Fill = new LinearGradientBrush(hairWhite, hairShadow, new Point(0, 0), new Point(0, 1)),
                Stroke = new SolidColorBrush(hairOutline),
                StrokeThickness = 1.8,
                StrokeLineJoin = PenLineJoin.Round
            };
            rightTailGrid.Children.Add(rightTailHair);

            rightTailGrid.Children.Add(new Rectangle { Width = 10, Height = 4, RadiusX = 2, RadiusY = 2, Fill = new SolidColorBrush(hoodDark), Stroke = new SolidColorBrush(hoodStroke), StrokeThickness = 1.2, Margin = new Thickness(6, 2, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            rightTailGrid.Children.Add(new Rectangle { Width = 10, Height = 1.8, RadiusX = 1, RadiusY = 1, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(6, 3, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            root.Children.Add(rightTailGrid);

            // 3. Cyber Legs & Boots
            Grid legsGrid = new Grid
            {
                Width = 44,
                Height = 24,
                Margin = new Thickness(0, 92, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top
            };

            // Left Cyber Boot
            Border leftBoot = new Border
            {
                Width = 12,
                Height = 18,
                CornerRadius = new CornerRadius(3, 3, 4, 4),
                Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                BorderBrush = new SolidColorBrush(hoodStroke),
                BorderThickness = new Thickness(1.4),
                Margin = new Thickness(6, 4, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            };
            legsGrid.Children.Add(leftBoot);
            // Left Boot Cyan Neon Band & Sole
            legsGrid.Children.Add(new Rectangle { Width = 10, Height = 2.5, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(7, 10, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            legsGrid.Children.Add(new Rectangle { Width = 12, Height = 3, RadiusX = 1.5, RadiusY = 1.5, Fill = Brushes.White, Stroke = new SolidColorBrush(hoodStroke), StrokeThickness = 1.0, Margin = new Thickness(6, 19, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            // Right Cyber Boot
            Border rightBoot = new Border
            {
                Width = 12,
                Height = 18,
                CornerRadius = new CornerRadius(3, 3, 4, 4),
                Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                BorderBrush = new SolidColorBrush(hoodStroke),
                BorderThickness = new Thickness(1.4),
                Margin = new Thickness(0, 4, 6, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top
            };
            legsGrid.Children.Add(rightBoot);
            // Right Boot Cyan Neon Band & Sole
            legsGrid.Children.Add(new Rectangle { Width = 10, Height = 2.5, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(0, 10, 7, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });
            legsGrid.Children.Add(new Rectangle { Width = 12, Height = 3, RadiusX = 1.5, RadiusY = 1.5, Fill = Brushes.White, Stroke = new SolidColorBrush(hoodStroke), StrokeThickness = 1.0, Margin = new Thickness(0, 19, 6, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });

            root.Children.Add(legsGrid);

            // 4. Cyber Body & Techwear Outfit
            Grid body = new Grid
            {
                Width = 54,
                Height = 40,
                Margin = new Thickness(0, 62, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top
            };

            // Pleated Tech Skirt
            Polygon skirt = new Polygon
            {
                Points = new PointCollection { new Point(12, 18), new Point(42, 18), new Point(48, 34), new Point(6, 34) },
                Fill = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 1.5
            };
            body.Children.Add(skirt);

            // Skirt Glowing Cyan Neon Hem
            body.Children.Add(new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 7 33 L 47 33"),
                Stroke = new SolidColorBrush(neonCyan),
                StrokeThickness = 2.2,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            });

            // Sleeveless Cyber Vest (Dark techwear body)
            Polygon vest = new Polygon
            {
                Points = new PointCollection { new Point(14, 0), new Point(40, 0), new Point(43, 19), new Point(11, 19) },
                Fill = new SolidColorBrush(Color.FromRgb(24, 24, 27)),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 1.5
            };
            body.Children.Add(vest);

            // Cyan Vertical Tech Lines on Vest
            body.Children.Add(new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 19 2 L 17 18 M 35 2 L 37 18"),
                Stroke = new SolidColorBrush(neonCyan),
                StrokeThickness = 1.6,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            });

            // Glowing Cyber Chest Core / Sensor
            Ellipse chestSensor = new Ellipse
            {
                Width = 6,
                Height = 6,
                Fill = new SolidColorBrush(neonCyan),
                Stroke = Brushes.White,
                StrokeThickness = 1.0,
                Margin = new Thickness(0, 6, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 6, Opacity = 0.9, ShadowDepth = 0 }
            };
            body.Children.Add(chestSensor);

            // Cyber Belt & Glowing Cyan Buckle
            body.Children.Add(new Rectangle { Width = 30, Height = 3.5, Fill = new SolidColorBrush(Color.FromRgb(9, 9, 11)), Margin = new Thickness(0, 16, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });
            body.Children.Add(new Rectangle { Width = 8, Height = 4.5, RadiusX = 1.5, RadiusY = 1.5, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(0, 15.5, 0, 0), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top });

            // Cyber Detached Sleeves / Cuffs
            // Left Arm & Cuff
            Border leftArm = new Border { Width = 8, Height = 14, Background = new SolidColorBrush(skinColor), CornerRadius = new CornerRadius(3), Margin = new Thickness(3, 4, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            body.Children.Add(leftArm);
            Border leftCuff = new Border { Width = 9, Height = 9, Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)), BorderBrush = new SolidColorBrush(hoodStroke), BorderThickness = new Thickness(1.0), CornerRadius = new CornerRadius(2), Margin = new Thickness(2, 10, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top };
            body.Children.Add(leftCuff);
            body.Children.Add(new Rectangle { Width = 7, Height = 1.8, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(3, 10, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });

            // Right Arm & Cuff
            Border rightArm = new Border { Width = 8, Height = 14, Background = new SolidColorBrush(skinColor), CornerRadius = new CornerRadius(3), Margin = new Thickness(0, 4, 3, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top };
            body.Children.Add(rightArm);
            Border rightCuff = new Border { Width = 9, Height = 9, Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)), BorderBrush = new SolidColorBrush(hoodStroke), BorderThickness = new Thickness(1.0), CornerRadius = new CornerRadius(2), Margin = new Thickness(0, 10, 2, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top };
            body.Children.Add(rightCuff);
            body.Children.Add(new Rectangle { Width = 7, Height = 1.8, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(0, 10, 3, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });

            root.Children.Add(body);

            // 5. Head Container (Cyber Cat Hoodie + Headset + Face)
            Grid headContainer = new Grid
            {
                Width = 84,
                Height = 74,
                Margin = new Thickness(0, 2, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.9)
            };
            _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
            headContainer.RenderTransform = _bodyBreatheTransform;

            // Cyber Antenna Rods (Sticking out of Hood top)
            // Left Antenna
            System.Windows.Shapes.Path leftAntenna = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 30 14 L 22 2"),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 2.0,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            };
            headContainer.Children.Add(leftAntenna);
            Ellipse leftAntennaTip = new Ellipse
            {
                Width = 5,
                Height = 5,
                Fill = new SolidColorBrush(neonCyan),
                Margin = new Thickness(20, 0, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 5, Opacity = 0.9, ShadowDepth = 0 }
            };
            headContainer.Children.Add(leftAntennaTip);

            // Right Antenna
            System.Windows.Shapes.Path rightAntenna = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 54 14 L 62 2"),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 2.0,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            };
            headContainer.Children.Add(rightAntenna);
            Ellipse rightAntennaTip = new Ellipse
            {
                Width = 5,
                Height = 5,
                Fill = new SolidColorBrush(neonCyan),
                Margin = new Thickness(0, 0, 20, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 5, Opacity = 0.9, ShadowDepth = 0 }
            };
            headContainer.Children.Add(rightAntennaTip);

            // Cyber Cat Ears on Hood
            // Left Ear
            Polygon leftCyberEar = new Polygon
            {
                Points = new PointCollection { new Point(14, 22), new Point(24, 6), new Point(34, 18) },
                Fill = new SolidColorBrush(hoodDark),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 2.0
            };
            headContainer.Children.Add(leftCyberEar);
            Polygon leftInnerCyan = new Polygon
            {
                Points = new PointCollection { new Point(17, 20), new Point(24, 9), new Point(30, 17) },
                Fill = new SolidColorBrush(neonCyan),
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 4, Opacity = 0.8, ShadowDepth = 0 }
            };
            headContainer.Children.Add(leftInnerCyan);

            // Right Ear
            Polygon rightCyberEar = new Polygon
            {
                Points = new PointCollection { new Point(70, 22), new Point(60, 6), new Point(50, 18) },
                Fill = new SolidColorBrush(hoodDark),
                Stroke = new SolidColorBrush(hoodStroke),
                StrokeThickness = 2.0
            };
            headContainer.Children.Add(rightCyberEar);
            Polygon rightInnerCyan = new Polygon
            {
                Points = new PointCollection { new Point(67, 20), new Point(60, 9), new Point(54, 17) },
                Fill = new SolidColorBrush(neonCyan),
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 4, Opacity = 0.8, ShadowDepth = 0 }
            };
            headContainer.Children.Add(rightInnerCyan);

            // Black Techwear Hood Silhouette
            Border hoodBack = new Border
            {
                Width = 72,
                Height = 62,
                Margin = new Thickness(0, 10, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                CornerRadius = new CornerRadius(36, 36, 26, 26),
                Background = new SolidColorBrush(hoodDark),
                BorderBrush = new SolidColorBrush(hoodStroke),
                BorderThickness = new Thickness(2.0),
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Colors.Black, BlurRadius = 10, Opacity = 0.35, ShadowDepth = 2 }
            };
            headContainer.Children.Add(hoodBack);

            // Chibi Porcelain Anime Face
            Border face = new Border
            {
                Width = 56,
                Height = 48,
                Margin = new Thickness(0, 20, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                CornerRadius = new CornerRadius(24, 24, 20, 20),
                Background = new SolidColorBrush(skinColor),
                BorderBrush = new SolidColorBrush(Color.FromRgb(74, 53, 37)),
                BorderThickness = new Thickness(1.6)
            };
            headContainer.Children.Add(face);

            // Eyes Grid (Animated scale for blink)
            Grid eyesGrid = new Grid
            {
                Width = 42,
                Height = 16,
                Margin = new Thickness(0, 31, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.5)
            };
            _eyesScaleY = new ScaleTransform(1.0, 1.0);
            eyesGrid.RenderTransform = _eyesScaleY;

            Grid leftEye = CreateCyberAnimeEye(true);
            leftEye.HorizontalAlignment = HorizontalAlignment.Left;
            Grid rightEye = CreateCyberAnimeEye(false);
            rightEye.HorizontalAlignment = HorizontalAlignment.Right;
            eyesGrid.Children.Add(leftEye);
            eyesGrid.Children.Add(rightEye);
            headContainer.Children.Add(eyesGrid);

            // Cute Cyber Digital Tear & Cheek Markings
            headContainer.Children.Add(new Border { Width = 10, Height = 5, CornerRadius = new CornerRadius(4), Background = new SolidColorBrush(Color.FromArgb(140, 251, 113, 133)), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(17, 42, 0, 0) });
            headContainer.Children.Add(new Border { Width = 10, Height = 5, CornerRadius = new CornerRadius(4), Background = new SolidColorBrush(Color.FromArgb(140, 251, 113, 133)), HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 42, 17, 0) });
            // Neon Cyan Digital Tech Tear Markings
            headContainer.Children.Add(new Rectangle { Width = 2.5, Height = 4, RadiusX = 1, RadiusY = 1, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(24, 43, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top });
            headContainer.Children.Add(new Rectangle { Width = 2.5, Height = 4, RadiusX = 1, RadiusY = 1, Fill = new SolidColorBrush(neonCyan), Margin = new Thickness(0, 43, 24, 0), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top });

            // Cute Anime Mouth
            headContainer.Children.Add(new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 38 45 Q 42 48 46 45"),
                Stroke = new SolidColorBrush(Color.FromRgb(74, 53, 37)),
                StrokeThickness = 1.6,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top
            });

            // Silver / Platinum Bangs framing face inside Hood
            headContainer.Children.Add(new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 15 22 C 22 14, 62 14, 69 22 C 61 20, 56 28, 52 23 C 46 30, 38 22, 32 28 C 28 22, 23 26, 15 22 Z"),
                Fill = new LinearGradientBrush(hairWhite, hairShadow, new Point(0, 0), new Point(0, 1)),
                Stroke = new SolidColorBrush(hairOutline),
                StrokeThickness = 1.8,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                Margin = new Thickness(0, 10, 0, 0)
            });

            // Cyber Headset / Audio Cans on Sides
            // Left Earpiece
            Border leftHeadphone = new Border
            {
                Width = 12,
                Height = 22,
                CornerRadius = new CornerRadius(5),
                Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                BorderBrush = new SolidColorBrush(hoodStroke),
                BorderThickness = new Thickness(1.5),
                Margin = new Thickness(4, 28, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            };
            headContainer.Children.Add(leftHeadphone);
            Ellipse leftHeadphoneRing = new Ellipse
            {
                Width = 7,
                Height = 12,
                Stroke = new SolidColorBrush(neonCyan),
                StrokeThickness = 1.6,
                Margin = new Thickness(6, 33, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 4, Opacity = 0.9, ShadowDepth = 0 }
            };
            headContainer.Children.Add(leftHeadphoneRing);

            // Right Earpiece
            Border rightHeadphone = new Border
            {
                Width = 12,
                Height = 22,
                CornerRadius = new CornerRadius(5),
                Background = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                BorderBrush = new SolidColorBrush(hoodStroke),
                BorderThickness = new Thickness(1.5),
                Margin = new Thickness(0, 28, 4, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top
            };
            headContainer.Children.Add(rightHeadphone);
            Ellipse rightHeadphoneRing = new Ellipse
            {
                Width = 7,
                Height = 12,
                Stroke = new SolidColorBrush(neonCyan),
                StrokeThickness = 1.6,
                Margin = new Thickness(0, 33, 6, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(0, 229, 255), BlurRadius = 4, Opacity = 0.9, ShadowDepth = 0 }
            };
            headContainer.Children.Add(rightHeadphoneRing);

            // 6. Floating Notification Badge (Orange Circle with "1")
            Border notifBadge = new Border
            {
                Width = 18,
                Height = 18,
                CornerRadius = new CornerRadius(9),
                Background = new LinearGradientBrush(Color.FromRgb(249, 115, 22), Color.FromRgb(234, 88, 12), new Point(0, 0), new Point(1, 1)),
                BorderBrush = Brushes.White,
                BorderThickness = new Thickness(1.2),
                Margin = new Thickness(0, 6, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = Color.FromRgb(234, 88, 12), BlurRadius = 6, Opacity = 0.6, ShadowDepth = 2 }
            };
            notifBadge.Child = new TextBlock
            {
                Text = "1",
                FontSize = 10,
                FontWeight = FontWeights.ExtraBold,
                Foreground = Brushes.White,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
                Margin = new Thickness(0, -1, 0, 0)
            };
            headContainer.Children.Add(notifBadge);

            root.Children.Add(headContainer);
            AddFXElements(root);
        }

        private Grid CreateCyberAnimeEye(bool isLeft)
        {
            Grid eyeBox = new Grid { Width = 14, Height = 16 };
            // Upper Cyber Eyelash Curve
            eyeBox.Children.Add(new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 0 3 Q 7 -1 14 3"),
                Stroke = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                StrokeThickness = 2.2,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            });
            // Vibrant Blue -> Glowing Cyan Cyber Iris
            eyeBox.Children.Add(new Ellipse
            {
                Width = 11,
                Height = 13,
                Margin = new Thickness(1.5, 2, 0, 0),
                Fill = new LinearGradientBrush(Color.FromRgb(2, 132, 199), Color.FromRgb(0, 229, 255), new Point(0, 0), new Point(0, 1))
            });
            // Big Sparkling Specular Highlight
            eyeBox.Children.Add(new Ellipse
            {
                Width = 4.8,
                Height = 5.2,
                Fill = Brushes.White,
                Margin = new Thickness(isLeft ? 3.5 : 2.5, 3, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            });
            // Mini Specular Reflection
            eyeBox.Children.Add(new Ellipse
            {
                Width = 2.2,
                Height = 2.2,
                Fill = Brushes.White,
                Margin = new Thickness(isLeft ? 6.5 : 6.5, 8.5, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            });
            return eyeBox;
        }

        // ==================== 5. CHIBI GRIM REAPER (THẦN CHẾT) ====================
        private void DrawGrimReaperGraphic(Grid root)
        {
            Color cloakDark = Color.FromRgb(17, 14, 24); // Midnight Obsidian Cloak
            Color cloakRim = Color.FromRgb(58, 50, 72); // Deep Indigo Highlight
            Color cyanFire = Color.FromRgb(34, 211, 238); // Piercing Cyan Soul Fire
            Color boneWhite = Color.FromRgb(248, 250, 252); // Skull Ivory
            Color darkShadow = Color.FromRgb(3, 7, 18); // Abyss Black

            // 1. Unified Grim Reaper Body & Cloak (Áo choàng bóng đêm ma mị)
            Grid reaperBody = new Grid
            {
                Width = 84,
                Height = 88,
                Margin = new Thickness(0, 12, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.9)
            };
            _bodyBreatheTransform = new ScaleTransform(1.0, 1.0);
            reaperBody.RenderTransform = _bodyBreatheTransform;

            // Shredded Spectral Cloak Hem (Tà áo rách tua rua bay bồng bềnh)
            System.Windows.Shapes.Path flowingRobe = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 16 38 C 10 52, 4 70, 8 84 C 16 78, 22 84, 28 76 C 34 84, 40 76, 46 86 C 52 76, 60 84, 68 76 C 74 84, 80 78, 80 82 C 84 70, 78 50, 72 38 Z"),
                Fill = new LinearGradientBrush(cloakDark, Color.FromRgb(8, 6, 12), new Point(0, 0), new Point(0, 1)),
                Stroke = new SolidColorBrush(cloakRim),
                StrokeThickness = 2.2,
                Effect = new System.Windows.Media.Effects.DropShadowEffect
                {
                    Color = Colors.Black,
                    BlurRadius = 14,
                    Opacity = 0.6,
                    ShadowDepth = 3
                }
            };
            reaperBody.Children.Add(flowingRobe);

            // Large Pointed Hood (Mũ trùm đầu chóp nhọn)
            System.Windows.Shapes.Path hoodedCowl = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 14 54 C 6 32, 18 8, 42 2 C 58 -2, 78 8, 82 28 C 86 42, 80 54, 72 54 C 66 48, 54 44, 44 44 C 32 44, 20 48, 14 54 Z"),
                Fill = new LinearGradientBrush(cloakDark, Color.FromRgb(24, 20, 32), new Point(0, 0), new Point(0.8, 1)),
                Stroke = new SolidColorBrush(cloakRim),
                StrokeThickness = 2.4,
                StrokeLineJoin = PenLineJoin.Round
            };
            reaperBody.Children.Add(hoodedCowl);

            // Pointed Cowl Peak
            System.Windows.Shapes.Path hoodTip = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 46 2 C 58 -4, 76 -2, 82 10 C 78 12, 68 8, 56 6 Z"),
                Fill = new SolidColorBrush(cloakDark),
                Stroke = new SolidColorBrush(cloakRim),
                StrokeThickness = 1.8
            };
            reaperBody.Children.Add(hoodTip);

            // Dark Void Inside Hood
            Border faceVoid = new Border
            {
                Width = 52,
                Height = 42,
                Margin = new Thickness(0, 14, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                CornerRadius = new CornerRadius(26, 26, 20, 20),
                Background = new SolidColorBrush(darkShadow)
            };
            reaperBody.Children.Add(faceVoid);

            // Badass Chibi Skull Face
            Grid skullGrid = new Grid
            {
                Width = 44,
                Height = 36,
                Margin = new Thickness(0, 16, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top
            };

            // Skull Cranium
            System.Windows.Shapes.Path cranium = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 6 18 C 4 6, 12 0, 22 0 C 32 0, 40 6, 38 18 C 40 22, 38 28, 32 28 C 30 32, 28 34, 26 34 L 18 34 C 16 34, 14 32, 12 28 C 6 28, 4 22, 6 18 Z"),
                Fill = new LinearGradientBrush(boneWhite, Color.FromRgb(203, 213, 225), new Point(0, 0), new Point(0, 1)),
                Stroke = new SolidColorBrush(Color.FromRgb(71, 85, 105)),
                StrokeThickness = 1.8,
                StrokeLineJoin = PenLineJoin.Round
            };
            skullGrid.Children.Add(cranium);

            // Fierce / Cool Slanted Eye Sockets (Mắt xếch góc cạnh tự tin, không còn bị xệ buồn rầu)
            Grid eyesGrid = new Grid
            {
                Width = 34,
                Height = 14,
                Margin = new Thickness(0, 8, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Top,
                RenderTransformOrigin = new Point(0.5, 0.5)
            };
            _eyesScaleY = new ScaleTransform(1.0, 1.0);
            eyesGrid.RenderTransform = _eyesScaleY;

            // Left Eye (Fierce V-Angle inwards)
            Grid leftEyeBox = new Grid { Width = 13, Height = 13, HorizontalAlignment = HorizontalAlignment.Left };
            leftEyeBox.Children.Add(new Polygon
            {
                Points = new PointCollection { new Point(0, 0), new Point(13, 3), new Point(11, 12), new Point(0, 9) },
                Fill = new SolidColorBrush(darkShadow)
            });
            leftEyeBox.Children.Add(new Ellipse
            {
                Width = 6.5,
                Height = 7.5,
                Fill = new SolidColorBrush(cyanFire),
                Margin = new Thickness(3, 2, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = cyanFire, BlurRadius = 10, Opacity = 0.95, ShadowDepth = 0 }
            });
            leftEyeBox.Children.Add(new Ellipse
            {
                Width = 2.2,
                Height = 2.2,
                Fill = Brushes.White,
                Margin = new Thickness(4, 3, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            });

            // Right Eye (Fierce V-Angle inwards)
            Grid rightEyeBox = new Grid { Width = 13, Height = 13, HorizontalAlignment = HorizontalAlignment.Right };
            rightEyeBox.Children.Add(new Polygon
            {
                Points = new PointCollection { new Point(0, 3), new Point(13, 0), new Point(13, 9), new Point(2, 12) },
                Fill = new SolidColorBrush(darkShadow)
            });
            rightEyeBox.Children.Add(new Ellipse
            {
                Width = 6.5,
                Height = 7.5,
                Fill = new SolidColorBrush(cyanFire),
                Margin = new Thickness(3, 2, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top,
                Effect = new System.Windows.Media.Effects.DropShadowEffect { Color = cyanFire, BlurRadius = 10, Opacity = 0.95, ShadowDepth = 0 }
            });
            rightEyeBox.Children.Add(new Ellipse
            {
                Width = 2.2,
                Height = 2.2,
                Fill = Brushes.White,
                Margin = new Thickness(4, 3, 0, 0),
                HorizontalAlignment = HorizontalAlignment.Left,
                VerticalAlignment = VerticalAlignment.Top
            });

            eyesGrid.Children.Add(leftEyeBox);
            eyesGrid.Children.Add(rightEyeBox);
            skullGrid.Children.Add(eyesGrid);

            // Cool Skull Grin (Nụ cười đầu lâu sắc sảo)
            System.Windows.Shapes.Path skullTeeth = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 15 25 C 18 27, 26 27, 29 25 M 17 24 L 17 28 M 20 24 L 20 28 M 22 24 L 22 28 M 24 24 L 24 28 M 27 24 L 27 28"),
                Stroke = new SolidColorBrush(Color.FromRgb(51, 65, 85)),
                StrokeThickness = 1.6,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            };
            skullGrid.Children.Add(skullTeeth);
            reaperBody.Children.Add(skullGrid);

            root.Children.Add(reaperBody);

            // 2. Magnificent Death Scythe (Cây Lưỡi Hái Tử Thần Hiên Ngang Quét Qua Đầu)
            Grid scytheGrid = new Grid
            {
                Width = 114,
                Height = 108,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
                RenderTransformOrigin = new Point(0.72, 0.58)
            };
            _scytheRotate = new RotateTransform(0);
            scytheGrid.RenderTransform = _scytheRotate;

            // Long Weathered Dark Ash Wood Staff (Cán gỗ mun liền mạch)
            System.Windows.Shapes.Path scytheStaff = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 84 14 L 81 100 L 85 100 L 88 14 Z"),
                Fill = new LinearGradientBrush(Color.FromRgb(92, 45, 18), Color.FromRgb(40, 16, 5), new Point(0, 0), new Point(1, 0)),
                Stroke = new SolidColorBrush(Color.FromRgb(24, 8, 2)),
                StrokeThickness = 1.0
            };

            // Ancient Iron Blade Socket (Khớp nối gắn lưỡi hái)
            System.Windows.Shapes.Path bladeSocket = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 80 12 L 90 12 L 88 20 L 82 20 Z"),
                Fill = new SolidColorBrush(Color.FromRgb(71, 85, 105)),
                Stroke = new SolidColorBrush(Color.FromRgb(15, 23, 42)),
                StrokeThickness = 1.2
            };

            // Enormous Overhead Crescent Blade (Lưỡi hái cong hình trăng khuyết quét ngang qua đầu)
            System.Windows.Shapes.Path scytheBlade = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 86 14 C 86 -4, 68 -12, 46 -6 C 26 2, 14 16, 6 34 C 20 20, 44 10, 86 14 Z"),
                Fill = new LinearGradientBrush(
                    Color.FromRgb(248, 250, 252), // Gleaming Pure Silver Blade
                    Color.FromRgb(71, 85, 105),   // Dark Steel Back Spine
                    new Point(0, 1),
                    new Point(1, 0)
                ),
                Stroke = new SolidColorBrush(Color.FromRgb(30, 41, 59)),
                StrokeThickness = 2.0,
                StrokeLineJoin = PenLineJoin.Round,
                Effect = new System.Windows.Media.Effects.DropShadowEffect
                {
                    Color = cyanFire,
                    BlurRadius = 14,
                    Opacity = 0.9,
                    ShadowDepth = 0
                }
            };

            // Cyan Soul Magic Runes on the Blade (Cổ tự ma thuật xanh phát quang)
            System.Windows.Shapes.Path bladeRunes = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 72 8 C 58 6, 42 10, 30 18"),
                Stroke = new SolidColorBrush(cyanFire),
                StrokeThickness = 2.0,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round
            };

            // Skeletal Bony Hand Firmly Grasping the Staff (Bàn tay xương nắm chắc cán hái)
            System.Windows.Shapes.Path skeletalHand = new System.Windows.Shapes.Path
            {
                Data = Geometry.Parse("M 80 62 C 80 57, 88 57, 88 62 C 88 67, 80 67, 80 62 Z M 78 64 L 88 64 M 78 61 L 88 61"),
                Fill = new SolidColorBrush(boneWhite),
                Stroke = new SolidColorBrush(Color.FromRgb(71, 85, 105)),
                StrokeThickness = 1.2
            };

            scytheGrid.Children.Add(scytheStaff);
            scytheGrid.Children.Add(bladeSocket);
            scytheGrid.Children.Add(scytheBlade);
            scytheGrid.Children.Add(bladeRunes);
            scytheGrid.Children.Add(skeletalHand);
            root.Children.Add(scytheGrid);

            AddFXElements(root);
        }

        private void AddFXElements(Grid root)
        {
            _sleepZ = new TextBlock { Text = "z Z Z", FontSize = 13, FontWeight = FontWeights.Bold, Foreground = new SolidColorBrush(Color.FromRgb(168, 85, 247)), Margin = new Thickness(78, -4, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, Visibility = _state == PetState.Sleeping ? Visibility.Visible : Visibility.Collapsed };
            root.Children.Add(_sleepZ);
        }

        private void SetupContinuousAnimations()
        {
            if (_bodyBreatheTransform != null)
            {
                DoubleAnimation breatheAnim = new DoubleAnimation { From = 1.0, To = 1.04, Duration = TimeSpan.FromSeconds(1.6), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut } };
                _bodyBreatheTransform.BeginAnimation(ScaleTransform.ScaleYProperty, breatheAnim);
            }

            if (_tailRotateTransform != null)
            {
                DoubleAnimation tailWagAnim = new DoubleAnimation { From = -20, To = 22, Duration = TimeSpan.FromSeconds(0.7), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut } };
                _tailRotateTransform.BeginAnimation(RotateTransform.AngleProperty, tailWagAnim);
            }

            if (_scytheRotate != null)
            {
                // Gentle eerie scythe sway
                DoubleAnimation scytheAnim = new DoubleAnimation { From = -12, To = 4, Duration = TimeSpan.FromSeconds(2.0), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut } };
                _scytheRotate.BeginAnimation(RotateTransform.AngleProperty, scytheAnim);
            }

            if (_tongueY != null)
            {
                DoubleAnimation tongueAnim = new DoubleAnimation { From = 0, To = 2.5, Duration = TimeSpan.FromSeconds(0.8), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut } };
                _tongueY.BeginAnimation(TranslateTransform.YProperty, tongueAnim);
            }

            if (_bellRotate != null)
            {
                DoubleAnimation bellAnim = new DoubleAnimation { From = -15, To = 15, Duration = TimeSpan.FromSeconds(0.6), AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever, EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut } };
                _bellRotate.BeginAnimation(RotateTransform.AngleProperty, bellAnim);
            }
        }

        private void StartTimers()
        {
            _behaviorTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(6.0) };
            _behaviorTimer.Tick += (s, e) => {
                Log("behaviorTimer tick");
                DecideNextAction();
            };
            _behaviorTimer.Start();

            _blinkTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(3.5) };
            _blinkTimer.Tick += (s, e) => {
                Log("blinkTimer tick");
                DoBlink();
            };
            _blinkTimer.Start();

            _earTwitchTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(4.5) };
            _earTwitchTimer.Tick += (s, e) => {
                Log("earTwitchTimer tick");
                DoEarTwitch();
            };
            _earTwitchTimer.Start();

            _speechTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(9) };
            _speechTimer.Tick += (s, e) => {
                Log("speechTimer tick");
                CycleSpeechText();
            };
            _speechTimer.Start();

            _syncTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2) };
            _syncTimer.Tick += (s, e) => {
                Log("syncTimer tick");
                SyncFromStateFile();
            };
            _syncTimer.Start();
        }

        private void DoBlink()
        {
            try
            {
                if (_eyesScaleY == null || _state == PetState.Sleeping || _isCelebrating) return;
                DoubleAnimation blinkAnim = new DoubleAnimation { From = 1.0, To = 0.1, Duration = TimeSpan.FromMilliseconds(100), AutoReverse = true, RepeatBehavior = new RepeatBehavior(1) };
                _eyesScaleY.BeginAnimation(ScaleTransform.ScaleYProperty, blinkAnim);
            }
            catch (Exception ex)
            {
                Log("Error in DoBlink: " + ex.Message);
            }
        }

        private void DoEarTwitch()
        {
            try
            {
                if (_state == PetState.Sleeping) return;
                bool twitchLeft = _random.Next(2) == 0;
                DoubleAnimation twitchAnim = new DoubleAnimation { From = 0, To = twitchLeft ? -15 : 15, Duration = TimeSpan.FromMilliseconds(120), AutoReverse = true, RepeatBehavior = new RepeatBehavior(2) };
                if (twitchLeft && _leftEarRotate != null) _leftEarRotate.BeginAnimation(RotateTransform.AngleProperty, twitchAnim);
                else if (!twitchLeft && _rightEarRotate != null) _rightEarRotate.BeginAnimation(RotateTransform.AngleProperty, twitchAnim);
            }
            catch (Exception ex)
            {
                Log("Error in DoEarTwitch: " + ex.Message);
            }
        }

        private void DecideNextAction()
        {
            try
            {
                if (_isCelebrating || _isDragging) return;
                
                // Riêng bé Cyber Neko chỉ đứng yên phát hoạt ảnh nhịp thở Idle, không đi lung tung
                if (_petType == "cyber")
                {
                    SetPetState(PetState.Idle);
                    return;
                }

                if (_isOverdue)
                {
                    WanderAcrossScreen(isFast: true);
                    return;
                }
                int action = _random.Next(10);
                if (action < 6) WanderAcrossScreen(isFast: false);
                else if (action < 8) DoHappyHops();
                else SetPetState(PetState.Idle);
            }
            catch (Exception ex)
            {
                Log("Error in DecideNextAction: " + ex.Message);
            }
        }

        private void WanderAcrossScreen(bool isFast)
        {
            try
            {
                SetPetState(PetState.Walking);
                double screenWidth = SystemParameters.WorkArea.Width;
                double nextX = 50 + _random.NextDouble() * (screenWidth - 380);

                _facingRight = nextX > Left;
                _flipTransform.ScaleX = _facingRight ? -1 : 1;
                Log(string.Format("Wander: Left={0:0}, nextX={1:0}, facingRight={2}, ScaleX={3}", Left, nextX, _facingRight, _flipTransform.ScaleX));

                double durationSec = isFast ? 1.6 : 2.8;
                DoubleAnimation moveAnim = new DoubleAnimation { To = nextX, Duration = TimeSpan.FromSeconds(durationSec), EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseInOut } };
                moveAnim.Completed += (s, e) => SetPetState(PetState.Idle);

                // Ghostly floating or walking bounce
                int stepCount = Math.Max(2, (int)(durationSec * 4.5));
                int repeatCount = _petType == "reaper" ? Math.Max(1, stepCount / 2) : stepCount;
                DoubleAnimation bounceAnim = new DoubleAnimation
                {
                    From = 0,
                    To = _petType == "reaper" ? -18 : (isFast ? -14 : -9),
                    Duration = TimeSpan.FromMilliseconds(_petType == "reaper" ? 450 : 220),
                    AutoReverse = true,
                    RepeatBehavior = new RepeatBehavior(repeatCount),
                    EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut }
                };
                _bounceTransform.BeginAnimation(TranslateTransform.YProperty, bounceAnim);

                if (_leftPawY != null && _rightPawY != null)
                {
                    DoubleAnimation pawAnim1 = new DoubleAnimation { From = 0, To = -6, Duration = TimeSpan.FromMilliseconds(220), AutoReverse = true, RepeatBehavior = new RepeatBehavior(stepCount) };
                    DoubleAnimation pawAnim2 = new DoubleAnimation { From = -6, To = 0, Duration = TimeSpan.FromMilliseconds(220), AutoReverse = true, RepeatBehavior = new RepeatBehavior(stepCount) };
                    _leftPawY.BeginAnimation(TranslateTransform.YProperty, pawAnim1);
                    _rightPawY.BeginAnimation(TranslateTransform.YProperty, pawAnim2);
                }

                BeginAnimation(Window.LeftProperty, moveAnim);
            }
            catch (Exception ex)
            {
                Log("Error in WanderAcrossScreen: " + ex.Message);
            }
        }

        private void DoHappyHops()
        {
            try
            {
                SetPetState(PetState.Happy);
                DoubleAnimation hopAnim = new DoubleAnimation { From = 0, To = -20, Duration = TimeSpan.FromMilliseconds(200), AutoReverse = true, RepeatBehavior = new RepeatBehavior(3), EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseOut } };
                hopAnim.Completed += (s, e) => SetPetState(PetState.Idle);
                _bounceTransform.BeginAnimation(TranslateTransform.YProperty, hopAnim);
                SpawnParticle(160, 160);
            }
            catch (Exception ex)
            {
                Log("Error in DoHappyHops: " + ex.Message);
            }
        }

        private void SetPetState(PetState newState)
        {
            _state = newState;
            if (_sleepZ != null) _sleepZ.Visibility = _state == PetState.Sleeping ? Visibility.Visible : Visibility.Collapsed;
        }

        private void UpdateSpeechText(bool advance = false)
        {
            try
            {
                if (_isCelebrating) return;

                string[] normalList = _petType == "reaper" ? _reaperPhrasesNormal
                                    : (_petType == "cyber" ? _cyberPhrasesNormal
                                    : (_petType == "cat" ? _catPhrasesNormal
                                    : (_petType == "anime" ? _animePhrasesNormal : _dogPhrasesNormal)));
                string[] panicList = _petType == "reaper" ? _reaperPhrasesPanic
                                   : (_petType == "cyber" ? _cyberPhrasesPanic
                                   : (_petType == "cat" ? _catPhrasesPanic
                                   : (_petType == "anime" ? _animePhrasesPanic : _dogPhrasesPanic)));

                string[] currentList = _isOverdue ? panicList : normalList;
                if (currentList == null || currentList.Length == 0) return;

                if (advance)
                {
                    _speechIndex = (_speechIndex + 1) % currentList.Length;
                }
                else
                {
                    if (_speechIndex >= currentList.Length) _speechIndex = 0;
                }

                if (_txtMessage != null)
                {
                    _txtMessage.Text = currentList[_speechIndex];
                }
            }
            catch (Exception ex)
            {
                Log("Error in UpdateSpeechText: " + ex.Message);
            }
        }

        private void CycleSpeechText()
        {
            UpdateSpeechText(true);
        }

        private void SpawnParticle(double startX, double startY)
        {
            try
            {
                string icon = "💖";
                if (_petType == "dog") icon = _random.Next(2) == 0 ? "🦴" : "🐾";
                else if (_petType == "cat") icon = _random.Next(2) == 0 ? "🐾" : "💖";
                else if (_petType == "anime") icon = _random.Next(2) == 0 ? "🌸" : "✨";
                else if (_petType == "cyber") icon = _random.Next(3) == 0 ? "⚡" : (_random.Next(2) == 0 ? "💻" : "✨");
                else if (_petType == "reaper") icon = _random.Next(3) == 0 ? "💀" : (_random.Next(2) == 0 ? "👻" : "⏳");

                TextBlock p = new TextBlock { Text = icon, FontSize = 18 };
                Canvas.SetLeft(p, startX + _random.Next(-25, 25));
                Canvas.SetTop(p, startY);
                _fxCanvas.Children.Add(p);

                DoubleAnimation floatUp = new DoubleAnimation { From = startY, To = startY - 50, Duration = TimeSpan.FromSeconds(1.2), EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseOut } };
                DoubleAnimation fadeOut = new DoubleAnimation { From = 1.0, To = 0.0, Duration = TimeSpan.FromSeconds(1.2) };
                floatUp.Completed += (s, e) => _fxCanvas.Children.Remove(p);

                p.BeginAnimation(Canvas.TopProperty, floatUp);
                p.BeginAnimation(UIElement.OpacityProperty, fadeOut);
            }
            catch (Exception ex)
            {
                Log("Error in SpawnParticle: " + ex.Message);
            }
        }

        private string ExtractJsonStringValue(string json, string key)
        {
            try
            {
                int keyIdx = json.IndexOf("\"" + key + "\"");
                if (keyIdx < 0) return null;
                int colonIdx = json.IndexOf(':', keyIdx + key.Length + 2);
                if (colonIdx < 0) return null;
                int firstQuote = json.IndexOf('"', colonIdx + 1);
                if (firstQuote < 0) return null;
                int secondQuote = json.IndexOf('"', firstQuote + 1);
                if (secondQuote < 0) return null;
                return json.Substring(firstQuote + 1, secondQuote - firstQuote - 1).Trim();
            }
            catch { return null; }
        }

        private void SyncFromStateFile()
        {
            try
            {
                if (!File.Exists(_statePath)) return;
                string json = "";
                using (var fs = new FileStream(_statePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                using (var sr = new StreamReader(fs))
                {
                    json = sr.ReadToEnd();
                }
                if (string.IsNullOrEmpty(json)) return;

                bool isExplicitlyDisabled = json.Contains("\"isPetEnabled\":false") || json.Contains("\"isPetEnabled\": false");
                if (isExplicitlyDisabled && !_isCelebrating)
                {
                    Log("SyncFromStateFile: pet is disabled in settings, closing window.");
                    Close();
                    return;
                }

                bool hasPending = json.Contains("\"hasPending\":true") || json.Contains("\"hasPending\": true");

                // Check petType sync from NotePro
                string newType = ExtractJsonStringValue(json, "petType");
                if (!string.IsNullOrEmpty(newType))
                {
                    newType = newType.ToLower();
                    if ((newType == "dog" || newType == "cat" || newType == "anime" || newType == "cyber" || newType == "reaper") && newType != _petType)
                    {
                        _petType = newType;
                        ApplyPetGraphic();
                        SetupContinuousAnimations();
                    }
                }

                if (!hasPending)
                {
                    if (_btnComplete != null) _btnComplete.Visibility = Visibility.Collapsed;
                    _speechBubble.BorderBrush = new SolidColorBrush(Color.FromRgb(99, 102, 241));

                    if (_petType == "dog")
                    {
                        _txtTitle.Text = "🐶 BẠN ĐỒNG HÀNH SHIBA";
                        _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(245, 158, 11));
                        _txtTask.Text = "Không có deadline nào cả! Bạn cứ thảnh thơi làm việc nha! 🐾";
                    }
                    else if (_petType == "cat")
                    {
                        _txtTitle.Text = "🐱 BÉ MÈO KAWAII";
                        _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(236, 72, 153));
                        _txtTask.Text = "Meo meo~ Công việc hôm nay đều ổn thỏa rồi, Senpai yên tâm nha! 💖";
                    }
                    else if (_petType == "anime")
                    {
                        _txtTitle.Text = "🌸 TRỢ LÝ WAIFU CHIBI";
                        _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(139, 92, 246));
                        _txtTask.Text = "Senpai ơi, không có việc gấp đâu ạ! Chúc Senpai một ngày vui vẻ! ✨";
                    }
                    else if (_petType == "cyber")
                    {
                        _txtTitle.Text = "⚡ BÉ CYBER NEKO NHẮC VIỆC";
                        _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(6, 182, 212));
                        _txtTask.Text = "Hệ thống đang hoạt động tối ưu! Không có deadline gấp, Master cứ an tâm nhé! 💙⚡";
                    }
                    else
                    {
                        _txtTitle.Text = "💀 THẦN CHẾT CHIBI";
                        _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(34, 211, 238));
                        _txtTask.Text = "Chưa có hạn chót nào cần gặt... Ta đang canh gác màn hình cho ngươi đấy! 👻";
                    }
                    return;
                }

                if (_btnComplete != null) _btnComplete.Visibility = Visibility.Visible;

                // Title
                string taskTitle = ExtractJsonStringValue(json, "title");
                if (!string.IsNullOrEmpty(taskTitle))
                {
                    _txtTask.Text = taskTitle;
                }

                // ID
                string taskId = ExtractJsonStringValue(json, "id");
                if (!string.IsNullOrEmpty(taskId))
                {
                    if (_currentDeadline == null) _currentDeadline = new DeadlineItem();
                    _currentDeadline.id = taskId;
                }

                _isOverdue = json.Contains("\"isOverdue\":true") || json.Contains("\"isOverdue\": true");
                if (_isOverdue)
                {
                    _txtTitle.Text = _petType == "reaper" ? "🚨 TỬ THẦN ĐẾN ĐÒI DEADLINE!"
                                   : (_petType == "cyber" ? "🚨 BÁO ĐỘNG ĐỎ: QUÁ HẠN!" : "🚨 DEADLINE ĐÃ QUÁ HẠN RỒI!");
                    _txtTitle.Foreground = Brushes.Red;
                    _speechBubble.BorderBrush = Brushes.Red;
                }
                else
                {
                    _txtTitle.Text = _petType == "reaper" ? "⚡ THẦN CHẾT ĐÒI HẠN CHÓT!"
                                   : (_petType == "cyber" ? "⚡ MASTER ƠI, CÓ NHIỆM VỤ NÈ!" : "⏰ HẠN CHÓT CẦN LÀM!");
                    _txtTitle.Foreground = _petType == "cyber" ? new SolidColorBrush(Color.FromRgb(6, 182, 212)) : new SolidColorBrush(Color.FromRgb(245, 158, 11));
                    _speechBubble.BorderBrush = _petType == "cyber" ? new SolidColorBrush(Color.FromRgb(6, 182, 212)) : new SolidColorBrush(Color.FromRgb(245, 158, 11));
                }
                UpdateSpeechText(false);
            }
            catch { }
        }

        private void MarkTaskCompleted()
        {
            try
            {
                if (_petType == "reaper")
                {
                    PlayGrimReaperCompletionAnimation();
                    return;
                }

                _isCelebrating = true;
                _txtTitle.Text = "🎉 THÀNH CÔNG VƯỢT DEADLINE!";
                _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(16, 185, 129));
                _txtMessage.Text = _petType == "dog" ? "Gâu gâu gâu!! 🎉 Chủ nhân giỏi nhất trần đời luôn! Woof woof~ 🦴💖"
                                 : (_petType == "anime" ? "Oa!! Senpai hoàn thành xong rồi, giỏi quá đi mất~ 🎉 (≧◡≦) ♡"
                                 : (_petType == "cyber" ? "Nhiệm vụ hoàn tất 100%! Overdrive kích hoạt thành công! Master đỉnh quá đi! 🚀⚡✨"
                                 : "Meo meo~ Tuyệt vời quá! Bạn đã hoàn thành công việc rồi nha! 💖"));
                _speechBubble.BorderBrush = new SolidColorBrush(Color.FromRgb(16, 185, 129));

                DoubleAnimation jumpAnim = new DoubleAnimation { From = 0, To = -40, Duration = TimeSpan.FromMilliseconds(260), AutoReverse = true, RepeatBehavior = new RepeatBehavior(5), EasingFunction = new BounceEase { Bounces = 1, Bounciness = 2 } };
                _bounceTransform.BeginAnimation(TranslateTransform.YProperty, jumpAnim);

                for (int i = 0; i < 7; i++)
                {
                    DispatcherTimer t = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(i * 280) };
                    t.Tick += (s, e) =>
                    {
                        t.Stop();
                        SpawnParticle(160 + _random.Next(-35, 35), 160);
                    };
                    t.Start();
                }

                string noteId = _currentDeadline != null ? _currentDeadline.id : "";
                string actionJson = "{\"action\":\"complete\",\"noteId\":\"" + noteId + "\",\"timestamp\":\"" + DateTime.Now.ToString("o") + "\"}";
                File.WriteAllText(_actionPath, actionJson);

                DispatcherTimer exitTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(3.0) };
                exitTimer.Tick += (s, e) =>
                {
                    exitTimer.Stop();
                    Close();
                };
                exitTimer.Start();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void PlayGrimReaperCompletionAnimation()
        {
            _isCelebrating = true;
            _txtTitle.Text = "🎉 THÀNH CÔNG VƯỢT DEADLINE!";
            _txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(34, 211, 238)); // Cyan
            _txtMessage.Text = "Khá lắm người phàm trần! Ngươi đã thoát được lưỡi hái lần này... Hẹn gặp lại nhé! 💀✨👻";
            _speechBubble.BorderBrush = new SolidColorBrush(Color.FromRgb(168, 85, 247)); // Purple

            // 1. Xoay lưỡi hái 360 độ siêu mượt (360-degree Scythe Spin)
            if (_scytheRotate != null)
            {
                DoubleAnimation spinAnim = new DoubleAnimation
                {
                    From = 0,
                    To = -360,
                    Duration = TimeSpan.FromMilliseconds(550),
                    EasingFunction = new CubicEase { EasingMode = EasingMode.EaseInOut }
                };
                spinAnim.Completed += (s, e) =>
                {
                    _scytheRotate.Angle = 0;
                };
                _scytheRotate.BeginAnimation(RotateTransform.AngleProperty, spinAnim);
            }

            // Nhún nhảy bay bổng nhẹ nhàng
            DoubleAnimation hoverLift = new DoubleAnimation
            {
                From = 0,
                To = -20,
                Duration = TimeSpan.FromMilliseconds(280),
                AutoReverse = true,
                RepeatBehavior = new RepeatBehavior(2),
                EasingFunction = new SineEase { EasingMode = EasingMode.EaseInOut }
            };
            _bounceTransform.BeginAnimation(TranslateTransform.YProperty, hoverLift);

            // Mưa linh hồn ma thuật bùng nổ
            for (int i = 0; i < 15; i++)
            {
                DispatcherTimer pt = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100 + i * 80) };
                pt.Tick += (s, e) =>
                {
                    pt.Stop();
                    SpawnParticle(160 + _random.Next(-35, 35), 150 + _random.Next(-20, 20));
                };
                pt.Start();
            }

            // Write completion to action file
            try
            {
                string noteId = _currentDeadline != null ? _currentDeadline.id : "";
                string actionJson = "{\"action\":\"complete\",\"noteId\":\"" + noteId + "\",\"timestamp\":\"" + DateTime.Now.ToString("o") + "\"}";
                File.WriteAllText(_actionPath, actionJson);
            }
            catch { }

            // Thần Chết bay vút lên trời & tan biến vào bóng đêm
            DispatcherTimer vanishTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1800) };
            vanishTimer.Tick += (s, e) =>
            {
                vanishTimer.Stop();

                DoubleAnimation floatSky = new DoubleAnimation
                {
                    From = 0,
                    To = -180,
                    Duration = TimeSpan.FromMilliseconds(1000),
                    EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseIn }
                };
                _bounceTransform.BeginAnimation(TranslateTransform.YProperty, floatSky);

                DoubleAnimation shrinkX = new DoubleAnimation
                {
                    From = 1.0,
                    To = 0.05,
                    Duration = TimeSpan.FromMilliseconds(1000),
                    EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseIn }
                };
                DoubleAnimation shrinkY = new DoubleAnimation
                {
                    From = 1.0,
                    To = 0.05,
                    Duration = TimeSpan.FromMilliseconds(1000),
                    EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseIn }
                };
                _petRoot.RenderTransformOrigin = new Point(0.5, 0.5);
                _flipTransform.BeginAnimation(ScaleTransform.ScaleXProperty, shrinkX);
                _flipTransform.BeginAnimation(ScaleTransform.ScaleYProperty, shrinkY);

                DoubleAnimation fadeOut = new DoubleAnimation
                {
                    From = 1.0,
                    To = 0.0,
                    Duration = TimeSpan.FromMilliseconds(950)
                };
                fadeOut.Completed += (s2, e2) => Close();

                _petRoot.BeginAnimation(UIElement.OpacityProperty, fadeOut);
                _speechBubble.BeginAnimation(UIElement.OpacityProperty, fadeOut);
            };
            vanishTimer.Start();
        }

        private void OpenNoteProApp()
        {
            try
            {
                Process[] procs = Process.GetProcessesByName("notepro");
                if (procs.Length > 0)
                {
                    IntPtr handle = procs[0].MainWindowHandle;
                    if (handle != IntPtr.Zero)
                    {
                        SetForegroundWindow(handle);
                        return;
                    }
                }

                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string[] candidates = new string[]
                {
                    System.IO.Path.Combine(baseDir, "notepro.exe"),
                    System.IO.Path.Combine(baseDir, "..", "notepro.exe"),
                    System.IO.Path.Combine(baseDir, "..", "build", "windows", "x64", "runner", "Debug", "notepro.exe"),
                    System.IO.Path.Combine(baseDir, "..", "build", "windows", "x64", "runner", "Release", "notepro.exe"),
                    @"D:\NotePro\build\windows\x64\runner\Debug\notepro.exe",
                    @"D:\NotePro\build\windows\x64\runner\Release\notepro.exe"
                };

                foreach (string candidate in candidates)
                {
                    if (File.Exists(candidate))
                    {
                        Process.Start(candidate);
                        break;
                    }
                }
            }
            catch { }
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        private static System.Threading.Mutex _mutex;

        public static void Log(string msg)
        {
            try
            {
                string logFile = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "pet_debug.log");
                System.IO.File.AppendAllText(logFile, DateTime.Now.ToString("HH:mm:ss.fff") + " " + msg + Environment.NewLine);
            }
            catch { }
        }

        [STAThread]
        public static void Main()
        {
            Log("=== DesktopPet starting ===");
            try
            {
                Process current = Process.GetCurrentProcess();
                foreach (Process p in Process.GetProcessesByName("DesktopPet"))
                {
                    if (p.Id != current.Id)
                    {
                        try { p.Kill(); } catch { }
                    }
                }

                Application app = new Application();
                app.DispatcherUnhandledException += (s, e) =>
                {
                    Log("DispatcherUnhandledException: " + e.Exception.ToString());
                    e.Handled = true;
                };

                var win = new PetWindow();
                Log("PetWindow instantiated. Running app...");
                app.Run(win);
                Log("app.Run exited.");
            }
            catch (Exception ex)
            {
                Log("Exception in Main: " + ex.ToString());
            }
        }
    }
}
