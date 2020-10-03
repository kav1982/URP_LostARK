using UnityEngine;

/// <summary>
/// 挂着摄像机上
/// 屏幕自适应   1920*1080的分辨率   摄像机的size设置为5.4（高的一半）
/// </summary>
public class ScreenAdaptation : MonoBehaviour
{   
    
    /// <summary>
     /// 单位宽度
     /// </summary>
    private float _devWidth = 19.2f;
   
    
    /// <summary>
    /// 屏幕高度/像素单位(默认100个像素一个单位) 
    /// </summary>
    private float _devHeight = 10.8f;


    /// <summary>
    /// 屏幕宽高比
    /// </summary>
    private float _aspectRatio;

    /// <summary>
    /// 相机视野尺寸
    /// 基本高度的一半
    /// </summary>
    private float _otrhographicSize;

    /// <summary>
    /// 相机应有宽度
    /// </summary>
    private float _cameraWidth;

    void Start()
    {
        _otrhographicSize = this.GetComponent<Camera>().orthographicSize;
        _aspectRatio = Screen.width * 1.0f / Screen.height;
        //根据真实屏幕比例计算相机应有的宽度
        _cameraWidth = _otrhographicSize * 2 * _aspectRatio;
        //如果设备的宽度大于摄像机的宽度的时候  调整摄像机的orthographicSize
        if (_cameraWidth < _devWidth)
        {
            _otrhographicSize = _devWidth / (2 * _aspectRatio);
            this.GetComponent<Camera>().orthographicSize = _otrhographicSize;
        }
    }

}