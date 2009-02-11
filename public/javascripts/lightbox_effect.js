function showBox(){
    $('overlay').show();
    center('box');
    return false;
}

function hideBox(){
    $('box').hide();
    $('overlay').hide();
    return false;
}

function center(element){
    try{
        element = $(element);
    }catch(e){
        return;
    }

    var my_width  = 0;
    var my_height = 0;

    if ( typeof( window.innerWidth ) == 'number' ){
        my_width  = window.innerWidth;
        my_height = window.innerHeight;
        alert("PYONG");
        alert("Width "+my_width+"  Height "+my_height)
    }else if ( document.documentElement && 
             ( document.documentElement.clientWidth ||
               document.documentElement.clientHeight ) ){
        my_width  = document.documentElement.clientWidth;
        my_height = document.documentElement.clientHeight;
        alert("PYONG PYONG");
        alert("Width "+my_width+"  Height "+my_height)
    }
    else if ( document.body &&
            ( document.body.clientWidth || document.body.clientHeight ) ){
        my_width  = document.body.clientWidth;
        my_height = document.body.clientHeight;
        alert("PYONG PYONG PYONG");
        alert("Width "+my_width+"  Height "+my_height);
    }

    element.style.position = 'absolute';
    element.style.zIndex   = 99;

    var scrollY = 0;

    if ( document.documentElement && document.documentElement.scrollTop ){
        scrollY = document.documentElement.scrollTop;
    }else if ( document.body && document.body.scrollTop ){
        scrollY = document.body.scrollTop;
    }else if ( window.pageYOffset ){
        scrollY = window.pageYOffset;
    }else if ( window.scrollY ){
        scrollY = window.scrollY;
    }

    var elementDimensions = Element.getDimensions(element);

    var setX = ( my_width  - elementDimensions.width  ) / 2;
    var setY = ( my_height - elementDimensions.height ) / 2 + scrollY;
    alert("elementDimensions width = "+elementDimensions.width+ "   elementDimensions height = "+elementDimensions.height);

    setX = ( setX < 0 ) ? 0 : setX;
    setY = ( setY < 0 ) ? 0 : setY;
    alert("setX "+setX+"  setY "+setY);

    element.style.left = setX + "px";
    element.style.top  = setY + "px";

    element.style.display  = 'block';
}